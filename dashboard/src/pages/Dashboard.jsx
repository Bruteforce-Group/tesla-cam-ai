import React, { useState, useEffect } from 'react';
import { useWebSocket } from '../contexts/WebSocketContext';
import { api } from '../services/api';
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  Alert,
  LinearProgress,
  IconButton,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Paper
} from '@mui/material';
import {
  VideoCameraFront,
  Warning,
  Security,
  DirectionsCar,
  Person,
  Storage,
  CloudUpload,
  Refresh
} from '@mui/icons-material';
import { format } from 'date-fns';
import { Line, Doughnut } from 'react-chartjs-2';
import VideoPlayer from '../components/VideoPlayer';
import AlertCard from '../components/AlertCard';

const Dashboard = () => {
  const { alerts, deviceStatus } = useWebSocket();
  const [stats, setStats] = useState(null);
  const [recentEvents, setRecentEvents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setRefreshing(true);
      
      // Load analytics
      const analyticsData = await api.getAnalytics();
      setStats(analyticsData.stats);
      
      // Load recent events
      const eventsData = await api.getEvents({ limit: 10 });
      setRecentEvents(eventsData.events);
      
      setLoading(false);
    } catch (error) {
      console.error('Error loading dashboard:', error);
    } finally {
      setRefreshing(false);
    }
  };

  const getStorageColor = (percent) => {
    if (percent > 90) return 'error';
    if (percent > 80) return 'warning';
    return 'success';
  };

  const StatCard = ({ icon, title, value, subtitle, color = 'primary' }) => (
    <Card>
      <CardContent>
        <Box display="flex" alignItems="center" justifyContent="space-between">
          <Box>
            <Typography color="textSecondary" gutterBottom variant="body2">
              {title}
            </Typography>
            <Typography variant="h4" component="h2">
              {value}
            </Typography>
            {subtitle && (
              <Typography variant="caption" color="textSecondary">
                {subtitle}
              </Typography>
            )}
          </Box>
          <Box color={`${color}.main`}>
            {icon}
          </Box>
        </Box>
      </CardContent>
    </Card>
  );

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="80vh">
        <LinearProgress style={{ width: '50%' }} />
      </Box>
    );
  }

  return (
    <Box sx={{ flexGrow: 1, p: 3 }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" component="h1">
          Tesla Camera AI Dashboard
        </Typography>
        <IconButton onClick={loadDashboardData} disabled={refreshing}>
          <Refresh />
        </IconButton>
      </Box>

      {/* Active Alerts */}
      {alerts.length > 0 && (
        <Box mb={3}>
          <Typography variant="h6" gutterBottom>
            Active Alerts
          </Typography>
          <Grid container spacing={2}>
            {alerts.slice(0, 3).map((alert) => (
              <Grid item xs={12} md={4} key={alert.id}>
                <AlertCard alert={alert} />
              </Grid>
            ))}
          </Grid>
        </Box>
      )}

      {/* Stats Grid */}
      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            icon={<VideoCameraFront fontSize="large" />}
            title="Total Events"
            value={stats?.total_events || 0}
            subtitle="Last 30 days"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            icon={<Security fontSize="large" />}
            title="Sentry Events"
            value={stats?.sentry_events || 0}
            subtitle="Security recordings"
            color="warning"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            icon={<Person fontSize="large" />}
            title="People Detected"
            value={stats?.person_detections || 0}
            subtitle="Total detections"
            color="error"
          />
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <StatCard
            icon={<DirectionsCar fontSize="large" />}
            title="Vehicles Detected"
            value={stats?.vehicle_detections || 0}
            subtitle="Total detections"
            color="info"
          />
        </Grid>
      </Grid>

      {/* Device Status and Storage */}
      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Device Status
              </Typography>
              {deviceStatus ? (
                <Box>
                  <Box display="flex" justifyContent="space-between" mb={2}>
                    <Typography variant="body2">Device ID</Typography>
                    <Typography variant="body2" fontWeight="bold">
                      {deviceStatus.device_id}
                    </Typography>
                  </Box>
                  <Box display="flex" justifyContent="space-between" mb={2}>
                    <Typography variant="body2">Last Seen</Typography>
                    <Chip
                      label="Online"
                      color="success"
                      size="small"
                      icon={<CloudUpload />}
                    />
                  </Box>
                  <Box mb={2}>
                    <Box display="flex" justifyContent="space-between" mb={1}>
                      <Typography variant="body2">Storage Used</Typography>
                      <Typography variant="body2">
                        {deviceStatus.storage_used_percent?.toFixed(1)}%
                      </Typography>
                    </Box>
                    <LinearProgress
                      variant="determinate"
                      value={deviceStatus.storage_used_percent || 0}
                      color={getStorageColor(deviceStatus.storage_used_percent)}
                    />
                  </Box>
                  <Box display="flex" justifyContent="space-between">
                    <Typography variant="body2">Upload Queue</Typography>
                    <Typography variant="body2" fontWeight="bold">
                      {deviceStatus.upload_queue_size || 0} files
                    </Typography>
                  </Box>
                </Box>
              ) : (
                <Alert severity="warning">Device offline</Alert>
              )}
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Detection Distribution
              </Typography>
              <Box height={200}>
                <Doughnut
                  data={{
                    labels: ['People', 'Vehicles', 'License Plates', 'Other'],
                    datasets: [{
                      data: [
                        stats?.person_detections || 0,
                        stats?.vehicle_detections || 0,
                        stats?.license_plates_detected || 0,
                        (stats?.total_detections || 0) - 
                          (stats?.person_detections || 0) - 
                          (stats?.vehicle_detections || 0) - 
                          (stats?.license_plates_detected || 0)
                      ],
                      backgroundColor: [
                        '#FF6384',
                        '#36A2EB',
                        '#FFCE56',
                        '#4BC0C0'
                      ]
                    }]
                  }}
                  options={{
                    maintainAspectRatio: false,
                    plugins: {
                      legend: {
                        position: 'right'
                      }
                    }
                  }}
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Recent Events */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Recent Events
          </Typography>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Time</TableCell>
                <TableCell>Type</TableCell>
                <TableCell>Camera</TableCell>
                <TableCell>Detections</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {recentEvents.map((event) => (
                <TableRow key={event.id}>
                  <TableCell>
                    {format(new Date(event.timestamp), 'MMM dd, HH:mm')}
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={event.event_type}
                      size="small"
                      color={event.event_type === 'sentry' ? 'warning' : 'default'}
                    />
                  </TableCell>
                  <TableCell>{event.camera}</TableCell>
                  <TableCell>
                    {event.detected_objects ? (
                      <Box display="flex" gap={0.5}>
                        {event.detected_objects.split(',').map((obj, idx) => (
                          <Chip key={idx} label={obj} size="small" variant="outlined" />
                        ))}
                      </Box>
                    ) : (
                      '-'
                    )}
                  </TableCell>
                  <TableCell>
                    <IconButton
                      size="small"
                      onClick={() => window.location.href = `/events/${event.id}`}
                    >
                      <VideoCameraFront />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </Box>
  );
};

export default Dashboard;
