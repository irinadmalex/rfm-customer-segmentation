# Расчет RFM для каждого клиента
  
WITH rfm_calc AS (
  SELECT
    customer_id,
    DATE_DIFF('2024-12-31', MAX(DATE(transaction_date)), DAY) AS recency,
    COUNT(DISTINCT transaction_id) AS frequency,
    ROUND(SUM(amount), 2) AS monetary
FROM `mytestproject1-477512.rfm_transactions.rfm_project`
GROUP BY customer_id
)
SELECT
  customer_id,
  recency,
  frequency,
  monetary
FROM rfm_calc
ORDER BY customer_id

# RFM-scoring
  
WITH rfm_calc AS (
  SELECT
    customer_id,
    DATE_DIFF('2024-12-31', MAX(DATE(transaction_date)), DAY) AS recency,
    COUNT(DISTINCT transaction_id) AS frequency,
    ROUND(SUM(amount), 2) AS monetary
  FROM `mytestproject1-477512.rfm_transactions.rfm_project`
  GROUP BY customer_id
),
rfm_scores AS (
  SELECT
    customer_id,
    recency,
    frequency,
    monetary,
    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
  FROM rfm_calc
)
SELECT *,
CONCAT(CAST(r_score AS STRING), CAST(f_score AS STRING), CAST(m_score AS STRING)) AS rfm_segment
FROM rfm_scores
ORDER BY customer_id

# Назначение названий сегментам

WITH rfm_calc AS (
  SELECT
    customer_id,
    DATE_DIFF('2024-12-31',MAX(DATE(transaction_date)), DAY) AS recency,
    COUNT(DISTINCT(transaction_id)) AS frequency,
    ROUND(SUM(amount), 2) AS monetary,
  FROM `mytestproject1-477512.rfm_transactions.rfm_project`
  GROUP BY customer_id
),
rfm_scores AS (
  SELECT
    customer_id,
    recency,
    frequency,
    monetary,
    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score,
  FROM rfm_calc
)
SELECT
  customer_id,
  r_score,
  f_score,
  m_score,
  recency,
  frequency,
  monetary,
  CASE
    WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'champions'
    WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'loyal'
    WHEN r_score >= 4  AND f_score <= 2 AND m_score <= 2 THEN 'new'
    WHEN r_score >= 3 AND f_score <= 3 AND m_score <= 3 THEN 'potential_loyal'
    WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'at_risk'
    WHEN r_score <= 2 AND f_score >= 4 THEN 'cant_lose'
    WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 3 THEN 'hibernating'
    WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'lost'
    ELSE 'others'
  END AS segment
FROM rfm_scores
ORDER BY customer_id

# Статистика по сегментам

WITH rfm_calc AS (
  SELECT
    customer_id,
    DATE_DIFF('2024-12-31', MAX(DATE(transaction_date)), DAY) AS recency,
    COUNT(DISTINCT transaction_id) AS frequency,
    ROUND(SUM(amount), 2) AS monetary,
  FROM `mytestproject1-477512.rfm_transactions.rfm_project`
  GROUP BY customer_id
),
rfm_scores AS (
  SELECT
    customer_id,
    recency,
    frequency,
    monetary,
    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score,
  FROM rfm_calc
),
segments AS (
  SELECT
    customer_id,
    r_score,
    f_score,
    m_score,
    recency,
    frequency,
    monetary,
    CASE
      WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'champions'
      WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'loyal'
      WHEN r_score >= 4 AND f_score <= 2 AND m_score <= 2 THEN 'new'
      WHEN r_score >= 3 AND f_score <= 3 AND m_score <= 3 THEN 'potential'
      WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'at_risk'
      WHEN r_score <= 2 AND f_score >= 4 THEN 'cant_lose'
      WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 3 THEN 'hibernating'
      WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'lost'
      ELSE 'others'
    END AS segment
  FROM rfm_scores
)
SELECT
  segment,
  COUNT(customer_id) AS customers,
  ROUND(AVG(recency), 1) AS avg_recency_days,
  ROUND(AVG(recency), 1) AS avg_frequency,
  ROUND(AVG(monetary), 2) AS avg_monetary,
  ROUND(SUM(monetary), 2) AS total_revenue,
  ROUND(AVG(monetary) * COUNT(customer_id), 2) AS segment_value
FROM segments
GROUP BY segment
ORDER BY total_revenue DESC
