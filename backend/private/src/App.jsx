import { useState, useEffect } from 'react';
import { Button } from './components/ui/button';
import { Input } from './components/ui/input';
import { Card, CardHeader, CardTitle, CardContent } from './components/ui/card';
import { PlusCircle, BookOpen, Brain, Layout, Calendar, RotateCcw, Check, X, BarChart } from 'lucide-react';
import TopicScheduleOverview from './components/TopicScheduleOverview';

function App() {
    const [subjects, setSubjects] = useState({});
    const [newSubject, setNewSubject] = useState('');
    const [newSubskill, setNewSubskill] = useState('');
    const [newTopic, setNewTopic] = useState('');
    const [selectedSubject, setSelectedSubject] = useState('');
    const [selectedSubskill, setSelectedSubskill] = useState('');
    const [scheduleData, setScheduleData] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [recommendations, setRecommendations] = useState([]);

    useEffect(() => {
        fetchSubjects();
        fetchRecommendations();
    }, []);

    const fetchSubjects = async () => {
        setLoading(true);
        try {
            const response = await fetch('http://localhost:5000/api/subjects');
            if (!response.ok) throw new Error('Failed to fetch subjects');
            const data = await response.json();
            setSubjects(data);
        } catch (error) {
            setError('Failed to load subjects');
            console.error('Error:', error);
        } finally {
            setLoading(false);
        }
    };

    const fetchRecommendations = async () => {
        try {
            const response = await fetch('http://localhost:5000/api/recommendations');
            if (!response.ok) throw new Error('Failed to fetch recommendations');
            const data = await response.json();
            setRecommendations(data);
        } catch (error) {
            console.error('Error fetching recommendations:', error);
        }
    };

    const addSubject = async () => {
        if (!newSubject) return;
        try {
            const response = await fetch('http://localhost:5000/api/subjects', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name: newSubject }),
            });
            if (!response.ok) throw new Error('Failed to add subject');
            await fetchSubjects();
            setNewSubject('');
        } catch (error) {
            setError('Failed to add subject');
            console.error('Error:', error);
        }
    };

    const refreshRecommendations = () => {
        fetchRecommendations();
    };

    const addSubskill = async () => {
        if (!selectedSubject || !newSubskill) return;
        try {
            const response = await fetch('http://localhost:5000/api/subskills', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    subject: selectedSubject,
                    name: newSubskill,
                }),
            });
            if (!response.ok) throw new Error('Failed to add subskill');
            await fetchSubjects();
            setNewSubskill('');
        } catch (error) {
            setError('Failed to add subskill');
            console.error('Error:', error);
        }
    };

    const addTopic = async () => {
        if (!selectedSubject || !selectedSubskill || !newTopic) return;
        try {
            const response = await fetch('http://localhost:5000/api/topics', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    subject: selectedSubject,
                    subskill: selectedSubskill,
                    name: newTopic,
                }),
            });
            if (!response.ok) throw new Error('Failed to add topic');
            await fetchSubjects();
            setNewTopic('');
        } catch (error) {
            setError('Failed to add topic');
            console.error('Error:', error);
        }
    };

    const updatePerformance = async (topic, newPerformance) => {
    try {
      // Make sure we have a topic ID from either topicId or id field
      const topicId = topic.topicId || topic.id;
      
      if (!topicId) {
        throw new Error('No topic ID available');
      }

      console.log('Updating performance for topic:', { topicId, newPerformance });
      
      const response = await fetch('http://localhost:5000/api/schedule', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          topicId: topicId,
          performance: newPerformance,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to update performance');
      }

      const data = await response.json();
      
      // Update local state
      setSubjects(prev => {
        const newSubjects = { ...prev };
        for (const [subject, subskills] of Object.entries(newSubjects)) {
          for (const [subskill, topics] of Object.entries(subskills)) {
            const topicIndex = topics.findIndex(t => (t.id === topicId || t.topicId === topicId));
            if (topicIndex !== -1) {
              topics[topicIndex] = {
                ...topics[topicIndex],
                performance: newPerformance,
                next_review: data.next_review,
                halflife: data.halflife
              };
            }
          }
        }
        return newSubjects;
      });

      // Update recommendations
      if (newPerformance > 0.7) {
        setRecommendations(prev => 
          prev.filter(rec => (rec.id !== topicId && rec.topicId !== topicId))
        );
      }

      // Refresh recommendations if needed
      if (recommendations.length <= 2) {
        fetchRecommendations();
      }

    } catch (error) {
      console.error('Error updating performance:', error);
      setError(error.message);
    }
  };

  // Render recommendations
  const renderRecommendations = () => (
    <Card>
      <CardHeader>
        <div className="flex justify-between items-center">
          <CardTitle className="flex items-center gap-2">
            <Calendar className="w-5 h-5" />
            Due for Review
          </CardTitle>
          <Button onClick={fetchRecommendations} variant="ghost" size="sm">
            <RotateCcw className="w-4 h-4" />
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        {loading ? (
          <div className="flex justify-center py-4">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
          </div>
        ) : recommendations.length === 0 ? (
          <p className="text-gray-500">No reviews due at this time.</p>
        ) : (
          <div className="space-y-3">
            {recommendations.map((rec) => (
              <div key={rec.topicId} className="p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                <div className="flex justify-between items-center">
                  <div>
                    <p className="font-medium">
                      {rec.subject} → {rec.subskill} → {rec.topic}
                    </p>
                    <p className="text-sm text-gray-600">
                      Last reviewed: {rec.lastReviewed ? new Date(rec.lastReviewed).toLocaleDateString() : 'Never'} | 
                      Performance: {(rec.performance * 100).toFixed()}%
                    </p>
                  </div>
                  <div className="flex gap-2">
                    <Button
                      onClick={() => updatePerformance(rec, Math.min(1, rec.performance + 0.1))}
                      className="bg-green-500 hover:bg-green-600"
                      title="Good performance"
                    >
                      <Check className="w-4 h-4" />
                    </Button>
                    <Button
                      onClick={() => updatePerformance(rec, Math.max(0, rec.performance - 0.1))}
                      className="bg-red-500 hover:bg-red-600"
                      title="Needs improvement"
                    >
                      <X className="w-4 h-4" />
                    </Button>
                  </div>
                </div>
                {rec.nextReview && (
                  <p className="text-sm text-gray-500 mt-2">
                    Next review: {new Date(rec.nextReview).toLocaleDateString()}
                  </p>
                )}
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  );

  // Render topic list
  const renderTopicList = (topics, subject, subskill) => (
    <div className="ml-8 space-y-3">
      {topics.map((topic) => (
        <div key={topic.id || topic.topicId} className="p-3 bg-gray-50 rounded">
          <div className="flex justify-between items-center">
            <div>
              <p className="font-medium">{topic.name}</p>
              <p className="text-sm text-gray-600">
                Last reviewed: {topic.last_reviewed ? new Date(topic.last_reviewed).toLocaleDateString() : 'Never'} | 
                Performance: {(topic.performance * 100).toFixed()}%
              </p>
            </div>
            <div className="flex gap-2">
              <Button
                onClick={() => updatePerformance(topic, Math.min(1, topic.performance + 0.1))}
                className="bg-green-500 hover:bg-green-600"
                title="Good performance"
              >
                <Check className="w-4 h-4" />
              </Button>
              <Button
                onClick={() => updatePerformance(topic, Math.max(0, topic.performance - 0.1))}
                className="bg-red-500 hover:bg-red-600"
                title="Needs improvement"
              >
                <X className="w-4 h-4" />
              </Button>
            </div>
          </div>
          {topic.next_review && (
            <p className="text-sm text-gray-500 mt-2">
              Next review: {new Date(topic.next_review).toLocaleDateString()}
            </p>
          )}
        </div>
      ))}
    </div>
  );



    const retrainModel = async () => {
        try {
            const response = await fetch('http://localhost:5000/api/retrain', {
                method: 'POST',
            });
            if (!response.ok) throw new Error('Failed to retrain model');
            const data = await response.json();
            console.log('Model retrained:', data);
        } catch (error) {
            setError('Failed to retrain model');
            console.error('Error:', error);
        }
    };

    return (
        <div className="min-h-screen bg-gray-50">
            <div className="container mx-auto p-6">
                <div className="flex justify-between items-center mb-8">
                    <h1 className="text-3xl font-bold">Learning Dashboard</h1>
                    <Button onClick={retrainModel} className="flex items-center gap-2">
                        <RotateCcw className="w-4 h-4" />
                        Retrain Model
                    </Button>
                </div>

                {error && (
                    <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-4">
                        {error}
                        <button
                            onClick={() => setError(null)}
                            className="float-right font-bold"
                        >
                            ×
                        </button>
                    </div>
                )}

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {renderRecommendations()}
                    {/* Add Subject Card */}
                    <Card>
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2">
                                <BookOpen className="w-5 h-5" />
                                Add Subject
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="flex gap-2">
                                <Input
                                    value={newSubject}
                                    onChange={(e) => setNewSubject(e.target.value)}
                                    placeholder="Enter subject name"
                                    disabled={loading}
                                />
                                <Button onClick={addSubject} disabled={loading || !newSubject}>
                                    <PlusCircle className="w-4 h-4 mr-2" />
                                    Add
                                </Button>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Add Subskill Card */}
                    <Card>
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2">
                                <Brain className="w-5 h-5" />
                                Add Subskill
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="flex flex-col gap-2">
                                <select
                                    className="p-2 border rounded"
                                    value={selectedSubject}
                                    onChange={(e) => setSelectedSubject(e.target.value)}
                                >
                                    <option value="">Select Subject</option>
                                    {Object.keys(subjects).map(subject => (
                                        <option key={subject} value={subject}>{subject}</option>
                                    ))}
                                </select>
                                <div className="flex gap-2">
                                    <Input
                                        value={newSubskill}
                                        onChange={(e) => setNewSubskill(e.target.value)}
                                        placeholder="Enter subskill name"
                                        disabled={!selectedSubject || loading}
                                    />
                                    <Button
                                        onClick={addSubskill}
                                        disabled={!selectedSubject || !newSubskill || loading}
                                    >
                                        <PlusCircle className="w-4 h-4 mr-2" />
                                        Add
                                    </Button>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Add Topic Card */}
                    <Card>
                        <CardHeader>
                            <CardTitle className="flex items-center gap-2">
                                <Layout className="w-5 h-5" />
                                Add Topic
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            <div className="flex flex-col gap-2">
                                <select
                                    className="p-2 border rounded"
                                    value={selectedSubject}
                                    onChange={(e) => {
                                        setSelectedSubject(e.target.value);
                                        setSelectedSubskill('');
                                    }}
                                >
                                    <option value="">Select Subject</option>
                                    {Object.keys(subjects).map(subject => (
                                        <option key={subject} value={subject}>{subject}</option>
                                    ))}
                                </select>
                                <select
                                    className="p-2 border rounded"
                                    value={selectedSubskill}
                                    onChange={(e) => setSelectedSubskill(e.target.value)}
                                    disabled={!selectedSubject}
                                >
                                    <option value="">Select Subskill</option>
                                    {selectedSubject &&
                                        Object.keys(subjects[selectedSubject] || {}).map(subskill => (
                                            <option key={subskill} value={subskill}>{subskill}</option>
                                        ))}
                                </select>
                                <div className="flex gap-2">
                                    <Input
                                        value={newTopic}
                                        onChange={(e) => setNewTopic(e.target.value)}
                                        placeholder="Enter topic name"
                                        disabled={!selectedSubject || !selectedSubskill || loading}
                                    />
                                    <Button
                                        onClick={addTopic}
                                        disabled={!selectedSubject || !selectedSubskill || !newTopic || loading}
                                    >
                                        <PlusCircle className="w-4 h-4 mr-2" />
                                        Add
                                    </Button>
                                </div>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Recommendations Card */}
                    <Card>
                        <CardHeader>
                            <div className="flex justify-between items-center">
                                <CardTitle className="flex items-center gap-2">
                                    <Calendar className="w-5 h-5" />
                                    Due for Review
                                </CardTitle>
                                <Button onClick={refreshRecommendations} variant="ghost" size="sm">
                                    <RotateCcw className="w-4 h-4" />
                                </Button>
                            </div>
                        </CardHeader>
                        <CardContent>
                            {loading ? (
                                <div className="flex justify-center py-4">
                                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
                                </div>
                            ) : recommendations.length === 0 ? (
                                <p className="text-gray-500">No reviews due at this time.</p>
                            ) : (
                                <div className="space-y-3">
                                    {recommendations.map((rec) => (
                                        <div key={rec.topicId} className="p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                                            {/* ... rest of your recommendation card content ... */}
                                        </div>
                                    ))}
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </div>

                {/* Learning Structure */}
                <Card className="mt-6">
                    <CardHeader>
                        <CardTitle>Learning Structure</CardTitle>
                    </CardHeader>
                    <CardContent>
                        {Object.entries(subjects).map(([subject, subskills]) => (
                            <div key={subject} className="mb-6">
                                <h3 className="text-xl font-semibold mb-2">{subject}</h3>
                                {Object.entries(subskills).map(([subskill, topics]) => (
                                    <div key={subskill} className="ml-4 mb-4">
                                        <h4 className="text-lg font-medium mb-2">• {subskill}</h4>
                                        <div className="ml-8 space-y-3">
                                            {topics.map((topic, index) => (
                                                <div key={index} className="p-3 bg-gray-50 rounded">
                                                    <div className="flex justify-between items-center">
                                                        <div>
                                                            <p className="font-medium">{topic.name}</p>
                                                            <p className="text-sm text-gray-600">
                                                                Last reviewed: {new Date(topic.last_reviewed).toLocaleDateString()} |
                                                                Performance: {(topic.performance * 100).toFixed()}%
                                                            </p>
                                                        </div>
                                                        <div className="flex gap-2">
                                                            <Button
                                                                onClick={() => updatePerformance(topic, Math.min(1, topic.performance + 0.1))}
                                                                className="bg-green-500 hover:bg-green-600"
                                                                title="Good performance"
                                                            >
                                                                <Check className="w-4 h-4" />
                                                            </Button>
                                                            <Button
                                                                onClick={() => updatePerformance(topic, Math.max(0, topic.performance - 0.1))}
                                                                className="bg-red-500 hover:bg-red-600"
                                                                title="Needs improvement"
                                                            >
                                                                <X className="w-4 h-4" />
                                                            </Button>
                                                        </div>
                                                    </div>
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                ))}
                            </div>
                        ))}
                    </CardContent>
                </Card>

                {/* Statistics */}
                <div className="mt-6 grid grid-cols-1 md:grid-cols-3 gap-4">
                    <Card>
                        <CardHeader>
                            <CardTitle>Total Topics</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-3xl font-bold">
                                {Object.values(subjects).reduce((acc, subskills) =>
                                    acc + Object.values(subskills).reduce((acc2, topics) =>
                                        acc2 + topics.length, 0
                                    ), 0
                                )}
                            </p>
                        </CardContent>
                    </Card>

                    <Card>
                        <CardHeader>
                            <CardTitle>Average Performance</CardTitle>
                        </CardHeader>
                        <CardContent>
                            {(() => {
                                const allTopics = Object.values(subjects).flatMap(subskills =>
                                    Object.values(subskills).flatMap(topics =>
                                        topics.map(topic => topic.performance)
                                    )
                                );
                                const avgPerformance = allTopics.length
                                    ? (allTopics.reduce((a, b) => a + b, 0) / allTopics.length * 100).toFixed()
                                    : 0;
                                return <p className="text-3xl font-bold">{avgPerformance}%</p>;
                            })()}
                        </CardContent>
                    </Card>

                    <Card>
                        <CardHeader>
                            <CardTitle>Due Today</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <p className="text-3xl font-bold">{recommendations.length}</p>
                        </CardContent>
                    </Card>
                </div>
             <TopicScheduleOverview subjects={subjects} />
            </div>
        </div>
    )
}

export default App
