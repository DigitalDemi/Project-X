import React from 'react';
import { Card, CardHeader, CardTitle, CardContent } from './ui/card';
import { Calendar } from 'lucide-react';

const TopicScheduleOverview = ({ subjects }) => {
  // Get all topics across all subjects and subskills
  const getAllTopics = () => {
    const allTopics = [];
    Object.entries(subjects).forEach(([subject, subskills]) => {
      Object.entries(subskills).forEach(([subskill, topics]) => {
        topics.forEach(topic => {
          allTopics.push({
            ...topic,
            subject,
            subskill,
          });
        });
      });
    });
    return allTopics;
  };

  // Group topics by review status
  const organizeTopics = () => {
    const topics = getAllTopics();
    const now = new Date();
    const tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const nextWeek = new Date(now);
    nextWeek.setDate(nextWeek.getDate() + 7);

    return {
      overdue: topics.filter(topic => {
        const reviewDate = topic.next_review ? new Date(topic.next_review) : null;
        return reviewDate && reviewDate < now;
      }),
      today: topics.filter(topic => {
        const reviewDate = topic.next_review ? new Date(topic.next_review) : null;
        return reviewDate && 
          reviewDate.toDateString() === now.toDateString();
      }),
      tomorrow: topics.filter(topic => {
        const reviewDate = topic.next_review ? new Date(topic.next_review) : null;
        return reviewDate && 
          reviewDate.toDateString() === tomorrow.toDateString();
      }),
      thisWeek: topics.filter(topic => {
        const reviewDate = topic.next_review ? new Date(topic.next_review) : null;
        return reviewDate && 
          reviewDate > tomorrow && 
          reviewDate <= nextWeek;
      }),
      later: topics.filter(topic => {
        const reviewDate = topic.next_review ? new Date(topic.next_review) : null;
        return reviewDate && reviewDate > nextWeek;
      }),
      unscheduled: topics.filter(topic => !topic.next_review),
    };
  };

  const renderTopicList = (topics, showPerformance = true) => (
    <div className="space-y-2">
      {topics.map(topic => (
        <div key={topic.id} className="p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
          <div className="flex justify-between items-start">
            <div>
              <p className="font-medium">
                {topic.subject} → {topic.subskill} → {topic.name}
              </p>
              <div className="text-sm text-gray-600 space-y-1">
                {showPerformance && (
                  <p>Performance: {(topic.performance * 100).toFixed()}%</p>
                )}
                {topic.last_reviewed && (
                  <p>Last reviewed: {new Date(topic.last_reviewed).toLocaleDateString()}</p>
                )}
                {topic.next_review && (
                  <p>Next review: {new Date(topic.next_review).toLocaleDateString()}</p>
                )}
              </div>
            </div>
            {topic.halflife && (
              <span className="text-sm text-gray-500">
                Halflife: {topic.halflife.toFixed(1)} days
              </span>
            )}
          </div>
        </div>
      ))}
    </div>
  );

  const organizedTopics = organizeTopics();

  return (
    <Card className="mt-6">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Calendar className="w-5 h-5" />
          Topic Review Schedule
        </CardTitle>
      </CardHeader>
      <CardContent>
        {/* Statistics */}
        <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mb-6">
          <div className="p-4 bg-red-50 rounded-lg">
            <p className="text-sm text-red-600">Overdue</p>
            <p className="text-2xl font-bold text-red-700">
              {organizedTopics.overdue.length}
            </p>
          </div>
          <div className="p-4 bg-blue-50 rounded-lg">
            <p className="text-sm text-blue-600">Due Today</p>
            <p className="text-2xl font-bold text-blue-700">
              {organizedTopics.today.length}
            </p>
          </div>
          <div className="p-4 bg-green-50 rounded-lg">
            <p className="text-sm text-green-600">This Week</p>
            <p className="text-2xl font-bold text-green-700">
              {organizedTopics.thisWeek.length}
            </p>
          </div>
        </div>

        {/* Overdue Topics */}
        {organizedTopics.overdue.length > 0 && (
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-red-600 mb-3">Overdue</h3>
            {renderTopicList(organizedTopics.overdue)}
          </div>
        )}

        {/* Today's Topics */}
        {organizedTopics.today.length > 0 && (
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-blue-600 mb-3">Due Today</h3>
            {renderTopicList(organizedTopics.today)}
          </div>
        )}

        {/* Tomorrow's Topics */}
        {organizedTopics.tomorrow.length > 0 && (
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-indigo-600 mb-3">Due Tomorrow</h3>
            {renderTopicList(organizedTopics.tomorrow)}
          </div>
        )}

        {/* This Week's Topics */}
        {organizedTopics.thisWeek.length > 0 && (
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-green-600 mb-3">Due This Week</h3>
            {renderTopicList(organizedTopics.thisWeek)}
          </div>
        )}

        {/* Later Topics */}
        {organizedTopics.later.length > 0 && (
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-gray-600 mb-3">Coming Up Later</h3>
            {renderTopicList(organizedTopics.later)}
          </div>
        )}

        {/* Unscheduled Topics */}
        {organizedTopics.unscheduled.length > 0 && (
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-gray-600 mb-3">Not Yet Scheduled</h3>
            {renderTopicList(organizedTopics.unscheduled, false)}
          </div>
        )}

        {Object.values(organizedTopics).every(topics => topics.length === 0) && (
          <p className="text-gray-500 text-center py-4">
            No topics added yet. Add some topics to see their review schedule.
          </p>
        )}
      </CardContent>
    </Card>
  );
};

export default TopicScheduleOverview;
