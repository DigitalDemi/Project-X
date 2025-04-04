from neo4j import GraphDatabase
from datetime import datetime
import json

password = f'qc7SCgkC.fN"^*+'

class Neo4jConnection:
    def __init__(self, uri="bolt://100.77.110.46:7687", user="neo4j", password=password):
        self.driver = GraphDatabase.driver(uri, auth=(user, password))

    def close(self):
        self.driver.close()

    def clear_database(self):
        with self.driver.session() as session:
            session.run("MATCH (n) DETACH DELETE n")

    def create_topic_node(self, topic_data):
        with self.driver.session() as session:
            # Create subject node if it doesn't exist
            session.run("""
                MERGE (s:Subject {name: $subject})
                """, subject=topic_data['subject'])

            # Create topic node
            result = session.run("""
                MATCH (s:Subject {name: $subject})
                CREATE (t:Topic {
                    id: $id,
                    name: $name,
                    status: $status,
                    stage: $stage,
                    created_at: $created_at,
                    next_review: $next_review
                })-[:BELONGS_TO]->(s)
                RETURN t
                """,
                id=topic_data['id'],
                name=topic_data['name'],
                subject=topic_data['subject'],
                status=topic_data['status'],
                stage=topic_data['stage'],
                created_at=topic_data['created_at'].isoformat(),
                next_review=topic_data['next_review'].isoformat()
            )

            for review in topic_data.get('review_history', []):
                session.run("""
                    MATCH (t:Topic {id: $topic_id})
                    CREATE (r:Review {
                        date: $date,
                        difficulty: $difficulty,
                        interval: $interval
                    })-[:REVIEW_OF]->(t)
                    """,
                    topic_id=topic_data['id'],
                    date=review['date'].isoformat(),
                    difficulty=review['difficulty'],
                    interval=review['interval']
                )

    def create_relationship(self, from_id, to_id, relationship_type="PREREQUISITE_OF"):
        with self.driver.session() as session:
            session.run("""
                MATCH (t1:Topic {id: $from_id})
                MATCH (t2:Topic {id: $to_id})
                MERGE (t1)-[r:%s]->(t2)
                """ % relationship_type,
                from_id=from_id,
                to_id=to_id
            )

    def get_full_graph(self):
        with self.driver.session() as session:
            # Get all nodes and relationships
            result = session.run("""
                MATCH (s:Subject)<-[:BELONGS_TO]-(t:Topic)
                OPTIONAL MATCH (t)-[r]->(t2:Topic)
                OPTIONAL MATCH (t)<-[:REVIEW_OF]-(rev:Review)
                RETURN s, t, collect(DISTINCT {type: type(r), target: t2.id}) as relationships,
                       collect(DISTINCT rev) as reviews
                """)
            
            graph_data = {"subjects": {}, "topics": {}, "relationships": []}
            
            for record in result:
                subject = record["s"]
                topic = record["t"]
                relationships = record["relationships"]
                reviews = record["reviews"]
                
                # Add subject if not exists
                if subject["name"] not in graph_data["subjects"]:
                    graph_data["subjects"][subject["name"]] = {
                        "name": subject["name"],
                        "topics": []
                    }
                
                # Add topic
                topic_data = dict(topic)
                topic_data["subject"] = subject["name"]
                topic_data["review_history"] = [
                    {
                        "date": datetime.fromisoformat(rev["date"]),
                        "difficulty": rev["difficulty"],
                        "interval": rev["interval"]
                    }
                    for rev in reviews if rev is not None
                ]
                topic_data["next_review"] = datetime.fromisoformat(topic_data["next_review"])
                topic_data["created_at"] = datetime.fromisoformat(topic_data["created_at"])
                
                graph_data["topics"][topic["id"]] = topic_data
                graph_data["subjects"][subject["name"]]["topics"].append(topic["id"])
                
                # Add relationships
                for rel in relationships:
                    if rel["target"]:
                        graph_data["relationships"].append({
                            "from": topic["id"],
                            "to": rel["target"],
                            "type": rel["type"]
                        })
            
            return graph_data

    def delete_topic(self, topic_id):
        with self.driver.session() as session:
            session.run("""
                MATCH (t:Topic {id: $id})
                OPTIONAL MATCH (t)<-[:REVIEW_OF]-(r:Review)
                DETACH DELETE t, r
                """,
                id=topic_id
            )

    def update_topic(self, old_id, new_data):
        with self.driver.session() as session:
            # First delete old topic
            self.delete_topic(old_id)
            # Then create new topic with updated data
            self.create_topic_node(new_data)
            # Relationships will need to be recreated manually

    def create_topic_node(self, topic_data):
        """Create a topic node with proper error handling and data validation."""
        with self.driver.session() as session:
            try:
                # Create subject node if it doesn't exist
                session.run("""
                    MERGE (s:Subject {name: $subject})
                    """, subject=topic_data['subject'])

                # Create topic node with proper date handling
                result = session.run("""
                    MATCH (s:Subject {name: $subject})
                    CREATE (t:Topic {
                        id: $id,
                        name: $name,
                        status: $status,
                        stage: $stage,
                        created_at: $created_at,
                        next_review: $next_review
                    })-[:BELONGS_TO]->(s)
                    RETURN t
                    """,
                    id=topic_data['id'],
                    name=topic_data['name'],
                    subject=topic_data['subject'],
                    status=topic_data['status'],
                    stage=topic_data['stage'],
                    created_at=topic_data['created_at'].isoformat(),
                    next_review=topic_data['next_review'].isoformat()
                )

                if 'review_history' in topic_data and topic_data['review_history']:
                    for review in topic_data['review_history']:
                        session.run("""
                            MATCH (t:Topic {id: $topic_id})
                            CREATE (r:Review {
                                date: $date,
                                difficulty: $difficulty,
                                interval: $interval
                            })-[:REVIEW_OF]->(t)
                            """,
                            topic_id=topic_data['id'],
                            date=review['date'].isoformat() if isinstance(review['date'], datetime) else review['date'],
                            difficulty=review['difficulty'],
                            interval=review['interval']
                        )
                
                return result
                
            except Exception as e:
                print(f"Database error in create_topic_node: {str(e)}")
                raise Exception(f"Failed to create topic: {str(e)}")

    def get_full_graph(self):
        """Get the full graph with proper date handling and error checking."""
        with self.driver.session() as session:
            try:
                result = session.run("""
                    MATCH (s:Subject)<-[:BELONGS_TO]-(t:Topic)
                    OPTIONAL MATCH (t)-[r]->(t2:Topic)
                    OPTIONAL MATCH (t)<-[:REVIEW_OF]-(rev:Review)
                    RETURN s, t, collect(DISTINCT {type: type(r), target: t2.id}) as relationships,
                        collect(DISTINCT rev) as reviews
                    """)
                
                graph_data = {"subjects": {}, "topics": {}, "relationships": []}
                
                for record in result:
                    subject = record["s"]
                    topic = record["t"]
                    relationships = record["relationships"]
                    reviews = record["reviews"]
                    
                    # Add subject if not exists
                    if subject["name"] not in graph_data["subjects"]:
                        graph_data["subjects"][subject["name"]] = {
                            "name": subject["name"],
                            "topics": []
                        }
                    
                    # Process topic data
                    topic_data = dict(topic)
                    topic_data["subject"] = subject["name"]
                    
                    # Process review history
                    topic_data["review_history"] = [
                        {
                            "date": datetime.fromisoformat(rev["date"]),
                            "difficulty": rev["difficulty"],
                            "interval": rev["interval"]
                        }
                        for rev in reviews if rev is not None
                    ]
                    
                    # Handle dates
                    topic_data["next_review"] = datetime.fromisoformat(topic_data["next_review"])
                    topic_data["created_at"] = datetime.fromisoformat(topic_data["created_at"])
                    
                    graph_data["topics"][topic["id"]] = topic_data
                    graph_data["subjects"][subject["name"]]["topics"].append(topic["id"])
                    
                    # Add relationships
                    for rel in relationships:
                        if rel["target"]:
                            graph_data["relationships"].append({
                                "from": topic["id"],
                                "to": rel["target"],
                                "type": rel["type"]
                            })
                
                return graph_data
                
            except Exception as e:
                print(f"Database error in get_full_graph: {str(e)}")
                raise Exception(f"Failed to retrieve graph: {str(e)}")
    def create_task(self, task_data: dict):
            with self.driver.session() as session:
                result = session.run("""
                    CREATE (t:Task {
                        id: $id,
                        title: $title,
                        is_completed: $is_completed,
                        created_at: $created_at,
                        due_date: $due_date,
                        energy_level: $energy_level,
                        duration: $duration
                    })
                    RETURN t
                    """,
                    id=task_data['id'],
                    title=task_data['title'],
                    is_completed=task_data.get('is_completed', False),
                    created_at=task_data['created_at'].isoformat(),
                    due_date=task_data.get('due_date', None),
                    energy_level=task_data.get('energy_level', None),
                    duration=task_data.get('duration', None)
                )
                return result.single()

    def create_calendar_event(self, event_data: dict):
        with self.driver.session() as session:
            result = session.run("""
                CREATE (e:Event {
                    id: $id,
                    title: $title,
                    start_time: $start_time,
                    end_time: $end_time,
                    type: $type,
                    description: $description
                })
                RETURN e
                """,
                id=event_data['id'],
                title=event_data['title'],
                start_time=event_data['start_time'].isoformat(),
                end_time=event_data['end_time'].isoformat(),
                type=event_data['type'],
                description=event_data.get('description', None)
            )
            return result.single()

    def get_tasks(self):
        with self.driver.session() as session:
            result = session.run("""
                MATCH (t:Task)
                RETURN t
                ORDER BY t.created_at DESC
                """)
            return [dict(record["t"]) for record in result]

    def get_calendar_events(self, start_date: datetime, end_date: datetime):
        with self.driver.session() as session:
            result = session.run("""
                MATCH (e:Event)
                WHERE datetime($start) <= datetime(e.start_time) <= datetime($end)
                RETURN e
                ORDER BY e.start_time
                """,
                start=start_date.isoformat(),
                end=end_date.isoformat()
            )
            return [dict(record["e"]) for record in result]

    def create_content_node(self, content_data):
        with self.driver.session() as session:
            result = session.run("""
                CREATE (c:Content {
                    id: $id,
                    title: $title,
                    type: $type,
                    content: $content,
                    created_at: $created_at
                })
                RETURN c
                """,
                id=content_data['id'],
                title=content_data['title'],
                type=content_data['type'],
                content=content_data['content'],
                created_at=content_data['created_at'].isoformat()
            )
            return result.single()

    def create_content_relationship(self, content_id, topic_id, relationship_type="EXPLAINS"):
        with self.driver.session() as session:
            session.run("""
                MATCH (c:Content {id: $content_id})
                MATCH (t:Topic {id: $topic_id})
                MERGE (c)-[r:%s]->(t)
                """ % relationship_type,
                content_id=content_id,
                topic_id=topic_id
            )
    def get_content_by_topic(self, topic_id):
        with self.driver.session() as session:
            try:
                result = session.run("""
                    MATCH (c:Content)-[:EXPLAINS]->(t:Topic {id: $topic_id})
                    RETURN c
                    """,
                    topic_id=topic_id
                )
                return [dict(record["c"]) for record in result]
            except Exception as e:
                print(f"Database error in get_content_by_topic: {str(e)}")
                return []

    def get_all_content(self):
        with self.driver.session() as session:
            result = session.run("""
                MATCH (c:Content)
                OPTIONAL MATCH (c)-[:EXPLAINS]->(t:Topic)
                RETURN c, collect(t.id) as related_topic_ids
                ORDER BY c.created_at DESC
                """)
            
            content_list = []
            for record in result:
                content = dict(record["c"])
                content["related_topic_ids"] = record["related_topic_ids"]
                content_list.append(content)
            
            return content_list

    def get_content_by_subject(self, subject: str):
        with self.driver.session() as session:
            result = session.run("""
                MATCH (c:Content)-[:EXPLAINS]->(t:Topic)-[:BELONGS_TO]->(s:Subject {name: $subject})
                RETURN c, collect(t.id) as related_topic_ids
                ORDER BY c.created_at DESC
                """,
                subject=subject
            )
            
            content_list = []
            for record in result:
                content = dict(record["c"])
                content["related_topic_ids"] = record["related_topic_ids"]
                content_list.append(content)
            
            return content_list

    def get_content_by_type(self, content_type: str):
        with self.driver.session() as session:
            result = session.run("""
                MATCH (c:Content {type: $type})
                OPTIONAL MATCH (c)-[:EXPLAINS]->(t:Topic)
                RETURN c, collect(t.id) as related_topic_ids
                ORDER BY c.created_at DESC
                """,
                type=content_type
            )
            
            content_list = []
            for record in result:
                content = dict(record["c"])
                content["related_topic_ids"] = record["related_topic_ids"]
                content_list.append(content)
            
            return content_list

    def search_content(self, query: str):
        with self.driver.session() as session:
            result = session.run("""
                MATCH (c:Content)
                WHERE toLower(c.title) CONTAINS toLower($query) OR toLower(c.content) CONTAINS toLower($query)
                OPTIONAL MATCH (c)-[:EXPLAINS]->(t:Topic)
                RETURN c, collect(t.id) as related_topic_ids
                ORDER BY c.created_at DESC
                """,
                query=query
            )
            
            content_list = []
            for record in result:
                content = dict(record["c"])
                content["related_topic_ids"] = record["related_topic_ids"]
                content_list.append(content)
            
            return content_list