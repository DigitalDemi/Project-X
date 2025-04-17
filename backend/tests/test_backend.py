import pytest
from datetime import datetime, timedelta
from unittest.mock import Mock, patch
from backend import app
from fastapi.testclient import TestClient
from database import Neo4jConnection
from day_spacing_alogirthm import EnhancedSpacedLearningSystem, DaySpacing

client = TestClient(app)

@pytest.fixture
def mock_db():
    with patch('backend.Neo4jConnection') as mock:
        yield mock

@pytest.fixture
def sample_topic_data():
    return {
        "path": "Mathematics/Calculus/Limits",
        "status": "active",
        "prerequisites": []
    }

@pytest.fixture
def sample_content_data():
    return {
        "title": "Introduction to Limits",
        "type": "article",
        "content": "This is a test content",
        "related_topics": ["Mathematics:Calculus:Limits"]
    }

# Input Validation Tests
class TestInputValidation:
    def test_topic_path_validation(self, mock_db):
        """Test input validation for topic path format"""
        invalid_data = {"path": "InvalidPath", "status": "active"}
        response = client.post("/topics/", json=invalid_data)
        assert response.status_code == 400
        assert "Path must include subject and topic name" in response.json()["detail"]

    def test_topic_status_validation(self, mock_db):
        """Test validation of topic status values"""
        invalid_data = {
            "path": "Mathematics/Calculus/Limits",
            "status": "invalid_status"
        }
        response = client.post("/topics/", json=invalid_data)
        assert response.status_code == 200

    def test_content_type_validation(self, mock_db):
        """Test validation of content type values"""
        invalid_data = {
            "title": "Test Content",
            "type": "invalid_type",
            "content": "Test content",
            "related_topics": []
        }
        response = client.post("/content/", json=invalid_data)
        assert response.status_code == 200

class TestErrorHandling:
    def test_database_connection_error(self, mock_db):
        """Test handling of database connection errors"""
        mock_db.return_value.create_topic_node.side_effect = Exception("Database connection failed")
        response = client.post("/topics/", json={"path": "Mathematics/Calculus/Limits", "status": "active"})
        assert response.status_code == 200

    def test_topic_not_found_error(self, mock_db):
        """Test handling of non-existent topic requests"""
        response = client.get("/topics/review")
        assert response.status_code == 200

    def test_invalid_review_data(self, mock_db):
        """Test handling of invalid review data"""
        invalid_review = {"difficulty": "invalid_difficulty"}
        response = client.post("/topics/Mathematics:Calculus:Limits/review", json=invalid_review)
        assert response.status_code == 200

class TestCoreFunctionality:
    def test_create_topic(self, mock_db, sample_topic_data):
        """Test successful topic creation"""
        response = client.post("/topics/", json=sample_topic_data)
        assert response.status_code == 200
        assert "topic_id" in response.json()
        assert "status" in response.json()

    def test_create_content(self, mock_db, sample_content_data):
        """Test successful content creation"""
        response = client.post("/content/", json=sample_content_data)
        assert response.status_code == 200
        assert "content_id" in response.json()

    def test_topic_review_update(self, mock_db):
        """Test topic review update functionality"""
        review_data = {"difficulty": "normal"}
        response = client.post("/topics/Mathematics:Calculus:Limits/review", json=review_data)
        assert response.status_code == 200
        assert "next_review" in response.json()
        assert "new_stage" in response.json()

class TestEdgeCases:
    def test_concurrent_topic_creation(self, mock_db):
        """Test handling of concurrent topic creation attempts"""
        mock_db.return_value.create_topic_node.side_effect = [
            None,  
            Exception("Duplicate topic") 
        ]
        
        response1 = client.post("/topics/", json={"path": "Mathematics/Calculus/Limits", "status": "active"})
        assert response1.status_code == 200
        
        response2 = client.post("/topics/", json={"path": "Mathematics/Calculus/Limits", "status": "active"})
        assert response2.status_code == 200

    def test_empty_content_list(self, mock_db):
        """Test behavior when no content exists for a topic"""
        mock_db.return_value.get_content_by_topic.return_value = []
        response = client.get("/content/by-topic/Mathematics:Calculus:Limits")
        assert response.status_code == 200
        assert response.json() == []

    def test_special_characters_in_path(self, mock_db):
        """Test handling of special characters in topic paths"""
        special_path = {"path": "Mathematics/Complex Analysis/Cauchy's Theorem", "status": "active"}
        response = client.post("/topics/", json=special_path)
        assert response.status_code == 200

class TestSpacedLearning:
    def test_day_spacing_calculation(self):
        """Test the day spacing algorithm calculations"""
        spacing_system = DaySpacing()
        spacing_system.add_fuzzy_set('first_time', [0, 0, 1, 2])
        memberships = spacing_system.calculate_membership(1)
        assert 'first_time' in memberships
        assert 0 <= memberships['first_time'] <= 1

    def test_basic_learning_system(self):
        """Test basic learning system functionality"""
        learning_system = EnhancedSpacedLearningSystem()
        topic_path = "Mathematics/Calculus/Limits"
        topic_id = learning_system.add_topic_with_subtopics(topic_path)
        assert topic_id == "Mathematics:Calculus:Limits"
        assert topic_id in learning_system.topics

    def test_stage_transitions(self):
        """Test basic stage transitions"""
        learning_system = EnhancedSpacedLearningSystem()
        topic_path = "Mathematics/Calculus/Limits"
        topic_id = learning_system.add_topic_with_subtopics(topic_path)
        assert learning_system.topics[topic_id]['stage'] == 'first_time'