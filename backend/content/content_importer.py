from neo4j import GraphDatabase
import uuid
from datetime import datetime
import argparse
import os
import json

# Neo4j connection settings
URI = "bolt://100.77.110.46:7687"
USER = "neo4j"
PASSWORD = "qc7SCgkC.fN\"^*+"

class ContentImporter:
    def __init__(self, uri, user, password):
        self.driver = GraphDatabase.driver(uri, auth=(user, password))
        
    def close(self):
        self.driver.close()
        
    def import_content(self, title, content_type, content_text, topic_ids):
        """Import content into Neo4j database"""
        with self.driver.session() as session:
            # Create a unique ID for the content
            content_id = f"content:{uuid.uuid4()}"
            created_at = datetime.now().isoformat()
            
            # Create content node
            session.run("""
                CREATE (c:Content {
                    id: $id,
                    title: $title,
                    type: $type,
                    content: $content,
                    created_at: $created_at
                })
                RETURN c
                """,
                id=content_id,
                title=title,
                type=content_type,
                content=content_text,
                created_at=created_at
            )
            
            print(f"✓ Created {content_type}: '{title}' (ID: {content_id})")
            
            # Create or find topics and link content
            for topic_id in topic_ids:
                try:
                    # Parse topic_id to extract subject and name
                    parts = topic_id.split(':')
                    if len(parts) != 2:
                        print(f"  ❌ Invalid topic ID format: {topic_id}. Expected format: subject:name")
                        continue
                        
                    subject, name = parts
                    
                    # Create topic if it doesn't exist
                    result = session.run("""
                        MERGE (t:Topic {id: $topic_id})
                        ON CREATE SET 
                            t.subject = $subject,
                            t.name = $name,
                            t.status = 'active',
                            t.stage = 'first_time',
                            t.created_at = $now,
                            t.next_review = $now
                        RETURN t.id, t.name, count(t) as count
                        """,
                        topic_id=topic_id,
                        subject=subject,
                        name=name.replace('_', ' ').title(),
                        now=datetime.now().isoformat()
                    )
                    
                    record = result.single()
                    if record and record["count"] == 1:
                        print(f"  ✓ Created new topic: {topic_id}")
                    
                    # Create relationship between content and topic
                    session.run("""
                        MATCH (c:Content {id: $content_id})
                        MATCH (t:Topic {id: $topic_id})
                        MERGE (c)-[:EXPLAINS]->(t)
                        """,
                        content_id=content_id,
                        topic_id=topic_id
                    )
                    
                    print(f"  ✓ Linked to topic: {topic_id}")
                        
                except Exception as e:
                    print(f"  ❌ Error with topic {topic_id}: {str(e)}")
            
            return content_id
            
    def import_from_file(self, file_path, content_type, topic_ids, title=None):
        """Import content from a file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as file:
                content = file.read()
                
            # Extract title from the first line if not provided and it's markdown
            if not title and content_type in ['article', 'guide']:
                first_line = content.strip().split('\n')[0]
                if first_line.startswith('# '):
                    title = first_line[2:].strip()
                else:
                    title = os.path.basename(file_path).split('.')[0]
            elif not title and content_type == 'quiz':
                # Try to extract title from JSON if it exists
                try:
                    data = json.loads(content)
                    if 'title' in data:
                        title = data['title']
                    else:
                        title = os.path.basename(file_path).split('.')[0]
                except:
                    title = os.path.basename(file_path).split('.')[0]
            
            return self.import_content(title, content_type, content, topic_ids)
            
        except Exception as e:
            print(f"❌ Error importing file {file_path}: {str(e)}")
            return None
            
    def validate_content_type(self, content_type):
        """Validate that content type is supported"""
        valid_types = ['article', 'guide', 'quiz']
        if content_type not in valid_types:
            raise ValueError(f"Content type must be one of: {', '.join(valid_types)}")

def main():
    parser = argparse.ArgumentParser(description='Import content into Neo4j database')
    parser.add_argument('--file', help='Path to content file')
    parser.add_argument('--type', choices=['article', 'guide', 'quiz'], help='Content type')
    parser.add_argument('--title', help='Content title (optional, will extract from file if not provided)')
    parser.add_argument('--topics', help='Comma-separated list of topic IDs to link to')
    
    args = parser.parse_args()
    
    if not args.file or not args.type or not args.topics:
        parser.print_help()
        return
        
    importer = ContentImporter(URI, USER, PASSWORD)
    try:
        topic_ids = [t.strip() for t in args.topics.split(',')]
        importer.import_from_file(args.file, args.type, topic_ids, args.title)
    finally:
        importer.close()

if __name__ == "__main__":
    main()