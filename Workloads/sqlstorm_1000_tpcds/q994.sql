WITH
cat_sales_agg AS (
  SELECT cs.cs_bill_customer_sk AS cust_sk,
         SUM(cs.cs_net_profit) AS cat_profit,
         COUNT(*) AS cat_txn,
         MIN(cs.cs_sold_date_sk) AS cat_first_date,
         MAX(cs.cs_sold_date_sk) AS cat_last_date
  FROM catalog_sales cs
  GROUP BY cs.cs_bill_customer_sk
),
store_sales_agg AS (
  SELECT ss.ss_customer_sk AS cust_sk,
         SUM(ss.ss_net_profit) AS store_profit,
         COUNT(*) AS store_txn,
         MIN(ss.ss_sold_date_sk) AS store_first_date,
         MAX(ss.ss_sold_date_sk) AS store_last_date
  FROM store_sales ss
  GROUP BY ss.ss_customer_sk
),
web_sales_agg AS (
  SELECT ws.ws_bill_customer_sk AS cust_sk,
         SUM(ws.ws_net_profit) AS web_profit,
         COUNT(*) AS web_txn,
         MIN(ws.ws_sold_date_sk) AS web_first_date,
         MAX(ws.ws_sold_date_sk) AS web_last_date
  FROM web_sales ws
  GROUP BY ws.ws_bill_customer_sk
),
cat_store_shared AS (
  SELECT cust_sk FROM cat_sales_agg INTERSECT SELECT cust_sk FROM store_sales_agg
),
top_cat AS (
  SELECT cust_sk, cat_profit,
         ROW_NUMBER() OVER (ORDER BY cat_profit DESC) AS rn
  FROM cat_sales_agg
  WHERE cat_profit > 0
),
top_store AS (
  SELECT cust_sk, store_profit,
         ROW_NUMBER() OVER (ORDER BY store_profit DESC) AS rn
  FROM store_sales_agg
  WHERE store_profit > 0
),
top_web AS (
  SELECT cust_sk, web_profit,
         ROW_NUMBER() OVER (ORDER BY web_profit DESC) AS rn
  FROM web_sales_agg
  WHERE web_profit > 0
),
union_top AS (
  SELECT cust_sk, cat_profit AS profit, 'catalog' AS channel FROM top_cat WHERE rn <= 20
  UNION ALL
  SELECT cust_sk, store_profit, 'store' FROM top_store WHERE rn <= 20
  UNION ALL
  SELECT cust_sk, web_profit, 'web' FROM top_web WHERE rn <= 20
),
combined_sales AS (
  SELECT
    COALESCE(c.cust_sk, s.cust_sk, w.cust_sk) AS cust_sk,
    c.cat_profit,
    c.cat_txn,
    s.store_profit,
    s.store_txn,
    w.web_profit,
    w.web_txn
  FROM cat_sales_agg c
  FULL OUTER JOIN store_sales_agg s ON c.cust_sk = s.cust_sk
  FULL OUTER JOIN web_sales_agg w ON COALESCE(c.cust_sk, s.cust_sk) = w.cust_sk
),
customer_detail AS (
  SELECT cu.c_customer_sk,
         cu.c_first_name,
         cu.c_last_name,
         cu.c_email_address,
         COALESCE(cu.c_preferred_cust_flag, 'N') AS preferred_flag,
         ca.ca_city,
         ca.ca_state,
         ca.ca_country,
         cd.cd_gender,
         cd.cd_marital_status,
         hd.hd_buy_potential
  FROM customer cu
  LEFT JOIN customer_address ca ON cu.c_current_addr_sk = ca.ca_address_sk
  LEFT JOIN customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN household_demographics hd ON cu.c_current_hdemo_sk = hd.hd_demo_sk
),
final_customer AS (
  SELECT
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.c_email_address,
    cd.preferred_flag,
    cd.ca_city,
    cd.ca_state,
    cd.ca_country,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.hd_buy_potential,
    COALESCE(cs.cat_profit, 0) AS cat_profit,
    COALESCE(cs.store_profit, 0) AS store_profit,
    COALESCE(cs.web_profit, 0) AS web_profit,
    COALESCE(cs.cat_txn, 0) + COALESCE(cs.store_txn, 0) + COALESCE(cs.web_txn, 0) AS total_txn,
    COALESCE(cs.cat_profit, 0) + COALESCE(cs.store_profit, 0) + COALESCE(cs.web_profit, 0) AS total_profit,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(cs.cat_profit, 0) + COALESCE(cs.store_profit, 0) + COALESCE(cs.web_profit, 0)) DESC) AS profit_rank,
    RANK() OVER (PARTITION BY cd.hd_buy_potential ORDER BY (COALESCE(cs.cat_profit, 0) + COALESCE(cs.store_profit, 0) + COALESCE(cs.web_profit, 0)) DESC) AS pot_rank
  FROM customer_detail cd
  LEFT JOIN combined_sales cs ON cd.c_customer_sk = cs.cust_sk
  WHERE (COALESCE(cs.cat_profit, 0) + COALESCE(cs.store_profit, 0) + COALESCE(cs.web_profit, 0)) > 0
),
last_sales AS (
  SELECT
    c.c_customer_sk,
    (SELECT MAX(cs.cs_sold_date_sk) FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = c.c_customer_sk) AS last_cat_date,
    (SELECT MAX(ss.ss_sold_date_sk) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) AS last_store_date,
    (SELECT MAX(ws.ws_sold_date_sk) FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS last_web_date
  FROM customer c
)
SELECT
  fc.c_customer_sk,
  fc.c_first_name,
  fc.c_last_name,
  CONCAT(fc.c_first_name, ' ', fc.c_last_name) AS full_name,
  fc.c_email_address,
  fc.preferred_flag,
  COALESCE(fc.ca_city, 'UNKNOWN') AS city,
  CASE
    WHEN fc.ca_state IN ('CA','NY','TX') THEN fc.ca_state
    WHEN fc.ca_state IS NULL THEN 'UNKNOWN'
    ELSE 'OTHER'
  END AS state_group,
  fc.ca_country,
  fc.cd_gender,
  fc.cd_marital_status,
  fc.hd_buy_potential,
  fc.total_profit,
  fc.total_txn,
  fc.profit_rank,
  fc.pot_rank,
  CASE
    WHEN fc.profit_rank <= 10 THEN 'Top10'
    WHEN fc.profit_rank <= 50 THEN 'Top50'
    WHEN fc.profit_rank <= 200 THEN 'Top200'
    ELSE 'Other'
  END AS profit_bucket,
  COALESCE(ls.last_cat_date, -1) AS last_cat_date_sk,
  COALESCE(ls.last_store_date, -1) AS last_store_date_sk,
  COALESCE(ls.last_web_date, -1) AS last_web_date_sk,
  fc.total_profit / NULLIF(fc.total_txn, 0) AS avg_profit_per_txn,
  CASE WHEN fc.c_customer_sk IN (SELECT cust_sk FROM cat_store_shared) THEN TRUE ELSE FALSE END AS shared_cat_store_flag,
  fc.total_profit * CASE WHEN fc.preferred_flag = 'Y' THEN 1.1 ELSE 1 END AS adjusted_profit
FROM final_customer fc
LEFT JOIN last_sales ls ON fc.c_customer_sk = ls.c_customer_sk
WHERE fc.profit_rank <= 500
ORDER BY fc.profit_rank
LIMIT 200
