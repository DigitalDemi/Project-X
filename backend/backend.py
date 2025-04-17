import uuid
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Optional
from datetime import datetime, timedelta
import json
from database import Neo4jConnection


class ContentCreate(BaseModel):
    title: str
    type: str  # "article", "guide", "quiz", etc.
    content: str
    related_topics: List[str] = []


app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

db = Neo4jConnection()

class TopicCreate(BaseModel):
    path: str
    status: str = 'active'
    prerequisites: List[str] = []

class TopicUpdate(BaseModel):
    difficulty: str

class TopicStatus(BaseModel):
    status: str

class TopicEdit(BaseModel):
    newPath: str
    status: Optional[str] = None
    prerequisites: List[str] = []

@app.post("/topics/")
async def create_topic(topic: TopicCreate):
    try:
        parts = topic.path.split('/')
        if len(parts) < 2:
            raise HTTPException(status_code=400, detail="Path must include subject and topic name")
        
        # Create topic data
        topic_data = {
            'id': topic.path.replace('/', ':'),
            'subject': parts[0],
            'name': parts[-1],
            'status': topic.status,
            'stage': 'first_time',
            'created_at': datetime.now(),
            'next_review': datetime.now(),
            'review_history': []
        }
        
        # Create topic in database
        try:
            db.create_topic_node(topic_data)
        except Exception as e:
            print(f"Database error: {str(e)}")
            raise HTTPException(status_code=500, detail="Failed to create topic in database")
        
        # Create prerequisite relationships
        for prereq in topic.prerequisites:
            try:
                db.create_relationship(prereq.replace('/', ':'), topic_data['id'])
            except Exception as e:
                print(f"Error creating prerequisite relationship: {str(e)}")
                # Don't fail the whole request if a prerequisite fails
                continue
        
        return {"topic_id": topic_data['id'], "status": "created"}
    except HTTPException:
        raise
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

@app.get("/topics/")
async def get_topics():
    graph_data = db.get_full_graph()
    return graph_data

@app.delete("/topics/{topic_id}")
async def delete_topic(topic_id: str):
    db.delete_topic(topic_id)
    return {"status": "deleted"}

@app.put("/topics/{topic_id}")
def update_topic(self, topic_id, topic_data):
    with self.driver.session() as session:
        session.run("""
            MATCH (t:Topic {id: $id})
            OPTIONAL MATCH (t)<-[:REVIEW_OF]-(r:Review)
            DETACH DELETE t, r
            """,
            id=topic_id
        )

        session.run("""
            MERGE (s:Subject {name: $subject})
            """, 
            subject=topic_data['subject']
        )

        session.run("""
            MATCH (s:Subject {name: $subject})
            CREATE (t:Topic {
                id: $id,
                name: $name,
                status: $status,
                stage: $stage,
                created_at: $created_at,
                next_review: $next_review
            })-[:BELONGS_TO]->(s)
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

@app.get("/topics/review")
async def get_due_reviews():
    """Get all topics that are due for review."""
    graph_data = db.get_full_graph()
    
    due_topics = {}
    current_time = datetime.now()
    
    for topic_id, topic in graph_data["topics"].items():
        if topic['status'] == 'active':
            if isinstance(topic['next_review'], str):
                next_review = datetime.fromisoformat(topic['next_review'])
            else:
                next_review = topic['next_review']
                
            if next_review <= current_time:
                due_topics[topic_id] = {
                    'id': topic_id,
                    'subject': topic['subject'],
                    'topic': topic['name'],
                    'stage': topic['stage'],
                    'next_review': next_review.isoformat()  
                }
    
    return due_topics

@app.post("/topics/{topic_id}/review")
async def review_topic(topic_id: str, update: TopicUpdate):
    graph_data = db.get_full_graph()
    if topic_id not in graph_data["topics"]:
        raise HTTPException(status_code=404, detail="Topic not found")
    
    topic_data = graph_data["topics"][topic_id].copy()  
    
  
    current_stage = topic_data['stage']
    stage_intervals = {
        'first_time': 1,
        'early_stage': 3,
        'mid_stage': 7,
        'late_stage': 14,
        'mastered': 30
    }
    
    base_interval = stage_intervals[current_stage]
    
    if update.difficulty == 'hard':
        interval = max(1, round(base_interval * 0.6))
        new_stage = _decrease_stage(current_stage)
    elif update.difficulty == 'easy':
        interval = round(base_interval * 1.4)
        new_stage = _increase_stage(current_stage)
    else:
        interval = base_interval
        new_stage = current_stage
    
    
    next_review = datetime.now() + timedelta(days=interval)
    
    
    topic_data['stage'] = new_stage
    topic_data['next_review'] = next_review
    topic_data['review_history'].append({
        'date': datetime.now(),
        'difficulty': update.difficulty,
        'interval': interval
    })
    
    # Update in database
    db.update_topic(topic_id, topic_data)
    
    return {
        "next_review": next_review.isoformat(),
        "new_stage": new_stage,
        "interval": interval
    }

def _decrease_stage(current_stage):
    stages = ['first_time', 'early_stage', 'mid_stage', 'late_stage', 'mastered']
    current_idx = stages.index(current_stage)
    return stages[max(0, current_idx - 1)]

def _increase_stage(current_stage):
    stages = ['first_time', 'early_stage', 'mid_stage', 'late_stage', 'mastered']
    current_idx = stages.index(current_stage)
    return stages[min(len(stages) - 1, current_idx + 1)]

@app.post("/content/")
async def create_content(content: ContentCreate):
    content_id = f"content:{uuid.uuid4()}"
    content_data = {
        "id": content_id,
        "title": content.title,
        "type": content.type,
        "content": content.content,
        "created_at": datetime.now()
    }
    
    db.create_content_node(content_data)
    
    # Create relationships to topics
    for topic_id in content.related_topics:
        db.create_content_relationship(content_id, topic_id)
    
    return {"content_id": content_id, "status": "created"}

@app.get("/content/{content_id}")
async def get_content(content_id: str):
    content = db.get_content(content_id)
    if not content:
        raise HTTPException(status_code=404, detail="Content not found")
    return content

@app.get("/content/by-topic/{topic_id}")
async def get_content_by_topic(topic_id: str):
    """Get all content related to a specific topic"""
    try:
        content_list = db.get_content_by_topic(topic_id)
        return content_list
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting content: {str(e)}")

@app.post("/content/")
async def create_content(content: ContentCreate):
    """Create new learning content for topics"""
    try:
        content_id = f"content:{uuid.uuid4()}"
        content_data = {
            "id": content_id,
            "title": content.title,
            "type": content.type,
            "content": content.content,
            "created_at": datetime.now().isoformat()
        }
        
        # Create content node in Neo4j
        db.create_content_node(content_data)
        
        # Create relationships to topics
        for topic_id in content.related_topics:
            db.create_content_relationship(content_id, topic_id)
        
        return {"content_id": content_id, "status": "created"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating content: {str(e)}")

@app.get("/content/by-subject/{subject}")
async def get_content_by_subject(subject: str):
    content_list = db.get_content_by_subject(subject)
    return content_list

@app.get("/content/by-type/{content_type}")
async def get_content_by_type(content_type: str):
    content_list = db.get_content_by_type(content_type)
    return content_list

@app.get("/content/search")
async def search_content(query: str):
    content_list = db.search_content(query)
    return content_list

@app.post("/study-sessions/")
async def create_study_session(session_data: dict):
    """Record a planned study session"""
    try:
        # Create a study session record in the database
        session_id = db.create_study_session({
            "id": f"session:{uuid.uuid4()}",
            "start_time": session_data["start_time"],
            "end_time": session_data["end_time"],
            "topics": session_data["topics"],
            "durations": session_data["durations"],
            "created_at": datetime.now().isoformat()
        })
        
        return {"session_id": session_id, "status": "created"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating study session: {str(e)}")

@app.get("/content/")
async def get_all_content():
    """Get all content resources"""
    try:
        content_list = db.get_all_content()
        return content_list
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting content: {str(e)}")

@app.on_event("shutdown")
async def shutdown_event():
    db.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)