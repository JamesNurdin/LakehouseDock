WITH
  sales_agg AS (
    SELECT
      cd.cd_gender,
      cd.cd_marital_status,
      ws.ws_bill_customer_sk,
      SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2002
      AND ws.ws_list_price > 100
    GROUP BY cd.cd_gender, cd.cd_marital_status, ws.ws_bill_customer_sk
  ),
  store_ret_agg AS (
    SELECT
      cd.cd_gender,
      cd.cd_marital_status,
      sr.sr_customer_sk,
      SUM(sr.sr_return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2002
      AND sr.sr_return_quantity > 0
    GROUP BY cd.cd_gender, cd.cd_marital_status, sr.sr_customer_sk
  )
SELECT
  COALESCE(s.cd_gender, r.cd_gender) AS gender,
  COALESCE(s.cd_marital_status, r.cd_marital_status) AS marital_status,
  COALESCE(s.ws_bill_customer_sk, r.sr_customer_sk) AS customer_sk,
  s.total_net_paid,
  r.total_return_amt,
  l.order_cnt
FROM sales_agg s
FULL OUTER JOIN store_ret_agg r
  ON s.ws_bill_customer_sk = r.sr_customer_sk
  AND s.cd_gender = r.cd_gender
  AND s.cd_marital_status = r.cd_marital_status
CROSS JOIN LATERAL (
  SELECT COUNT(*) AS order_cnt
  FROM web_sales ws3
  WHERE ws3.ws_bill_customer_sk = COALESCE(s.ws_bill_customer_sk, r.sr_customer_sk)
) AS l
WHERE (s.total_net_paid > 500 OR r.total_return_amt > 300)
UNION
SELECT
  COALESCE(s2.cd_gender, r2.cd_gender) AS gender,
  COALESCE(s2.cd_marital_status, r2.cd_marital_status) AS marital_status,
  COALESCE(s2.ws_bill_customer_sk, r2.sr_customer_sk) AS customer_sk,
  s2.total_net_paid,
  r2.total_return_amt,
  l2.order_cnt
FROM sales_agg s2
FULL OUTER JOIN store_ret_agg r2
  ON s2.ws_bill_customer_sk = r2.sr_customer_sk
  AND s2.cd_gender = r2.cd_gender
  AND s2.cd_marital_status = r2.cd_marital_status
CROSS JOIN LATERAL (
  SELECT COUNT(*) AS order_cnt
  FROM web_sales ws4
  WHERE ws4.ws_bill_customer_sk = COALESCE(s2.ws_bill_customer_sk, r2.sr_customer_sk)
    AND ws4.ws_list_price BETWEEN 50 AND 100
) AS l2
WHERE (s2.total_net_paid BETWEEN 200 AND 500 OR r2.total_return_amt BETWEEN 100 AND 300)
LIMIT 100
