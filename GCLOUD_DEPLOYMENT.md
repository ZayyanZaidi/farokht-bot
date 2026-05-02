# GCloud Deployment Guide - Farokht Bot Backend

## 📍 Current Deployment Status

**✅ Backend is Live**
- **URL**: `https://farokht-bot-backend-784756226072.us-central1.run.app`
- **Region**: us-central1 (Iowa, USA)
- **Auto-scaling**: Enabled (0-100 instances)
- **Memory**: 512MB default
- **Timeout**: 3600 seconds

---

## 🚀 How to Deploy Updated Code

### Option 1: Using gcloud CLI (Recommended)

```bash
# 1. Ensure you're in the backend directory
cd backend

# 2. Build and deploy
gcloud run deploy farokht-bot-backend \
  --source . \
  --runtime python313 \
  --region us-central1 \
  --allow-unauthenticated \
  --env-vars-file=.env.yaml \
  --memory 512Mi \
  --cpu 1 \
  --timeout 3600

# 3. Check deployment
gcloud run describe farokht-bot-backend --region us-central1
```

### Option 2: Using Dockerfile (for customization)

```bash
# 1. Build image locally
docker build -t farokht-bot-backend:latest .

# 2. Tag for GCloud
docker tag farokht-bot-backend:latest \
  gcr.io/PROJECT_ID/farokht-bot-backend:latest

# 3. Push to GCloud container registry
docker push gcr.io/PROJECT_ID/farokht-bot-backend:latest

# 4. Deploy
gcloud run deploy farokht-bot-backend \
  --image gcr.io/PROJECT_ID/farokht-bot-backend:latest \
  --region us-central1 \
  --allow-unauthenticated
```

---

## 📋 Deployment Checklist

Before deploying:

- [ ] All code changes committed
- [ ] Tests pass locally
- [ ] No API keys exposed in code
- [ ] `requirements.txt` is up to date
- [ ] `main.py` has correct port (8080 for GCloud, 8001 for local)
- [ ] Environment variables configured

---

## 🔧 Environment Configuration

### Required Files

**requirements.txt** ✅
```
fastapi
uvicorn
python-multipart
pydantic
chromadb
requests
```

**.gcloudignore** (Optional but recommended)
```
.git
.gitignore
__pycache__/
*.pyc
.venv/
venv/
test_queries.py
```

**.env.yaml** (For sensitive data)
```yaml
FAROKHT_API_KEY: "your-api-key-here"
DATABASE_PATH: "./chroma_data"
```

---

## 🔍 Monitoring & Debugging

### View Logs
```bash
# Real-time logs
gcloud run logs read farokht-bot-backend --region us-central1 --limit 50 --follow

# Logs from specific time
gcloud run logs read farokht-bot-backend \
  --region us-central1 \
  --limit 100 \
  --start-time "2024-05-03T10:00:00Z"
```

### View Metrics
```bash
# CPU usage
gcloud run services describe farokht-bot-backend --region us-central1

# More detailed metrics via Cloud Console:
# https://console.cloud.google.com/run/detail/us-central1/farokht-bot-backend
```

### Test the Deployment
```bash
# Health check
curl https://farokht-bot-backend-784756226072.us-central1.run.app/health

# Test chat endpoint
curl -X POST "https://farokht-bot-backend-784756226072.us-central1.run.app/chat" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "message=show me kurtas&lang=en"
```

---

## 🛑 Troubleshooting

### 503 Service Unavailable
- Backend might be reloading/syncing products
- Try again after 30 seconds
- Check logs: `gcloud run logs read`

### 504 Gateway Timeout
- Query is taking too long
- Database might be large
- Increase timeout in deployment

### Connection Refused
- Service not deployed or stopped
- Check status: `gcloud run services list --region us-central1`

### High Memory Usage
- Too many vector embeddings
- Increase memory: add `--memory 1Gi` flag
- OR reduce product batch size

---

## 📊 Performance Tuning

### For Better Response Times

1. **Memory**: Increase to 1GB for faster processing
   ```bash
   --memory 1Gi
   ```

2. **CPU**: Add more CPU
   ```bash
   --cpu 2
   ```

3. **Concurrency**: Set maximum concurrent requests
   ```bash
   --concurrency 100
   ```

### Scaling Settings
```bash
gcloud run services update farokht-bot-backend \
  --region us-central1 \
  --max-instances 100 \
  --min-instances 1
```

---

## 🔐 Security Considerations

1. **API Key Protection**
   - Store in `.env.yaml`, never in code
   - Set environment variable in GCloud

2. **CORS Settings**
   - Currently allows all origins: `"*"`
   - In production, restrict to app domains only
   ```python
   allow_origins=["https://yourdomain.com"]
   ```

3. **Rate Limiting** (Optional)
   - Add middleware to limit requests per IP
   - Prevents abuse

4. **Authentication**
   - Currently allows unauthenticated access
   - For private deployment: remove `--allow-unauthenticated`

---

## 📱 Integration with Flutter App

### Update App Configuration (if needed)

In `app/lib/services/api_service.dart`:
```dart
static const String _defaultUrl = 'https://farokht-bot-backend-784756226072.us-central1.run.app';
```

The app automatically uses this URL. No changes needed unless URL changes!

---

## 🎯 Deployment Tips

1. **Test locally first**
   ```bash
   cd backend
   python main.py
   # Visit http://localhost:8001
   ```

2. **Check requirements.txt**
   ```bash
   pip freeze > requirements.txt
   ```

3. **Commit changes**
   ```bash
   git add -A
   git commit -m "Update query handling and gcloud backend"
   git push
   ```

4. **Deploy**
   ```bash
   gcloud run deploy farokht-bot-backend \
     --source . \
     --region us-central1 \
     --allow-unauthenticated
   ```

5. **Verify**
   ```bash
   # Wait 2-3 minutes for deployment
   curl https://farokht-bot-backend-784756226072.us-central1.run.app/health
   ```

---

## 📞 Support

For GCloud issues:
- Check Cloud Build logs: `gcloud builds log`
- View service details: Cloud Console → Cloud Run
- Check quotas: `gcloud compute project-info describe`

For app issues:
- Test with local backend first
- Check app logs in Flutter
- Verify API key is set correctly

