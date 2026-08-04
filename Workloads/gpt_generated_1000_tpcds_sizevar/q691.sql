WITH
  ss AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_net_profit,
      d_ss.d_year,
      ca1.ca_state,
      cd1.cd_gender,
      hd1.hd_income_band_sk
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN customer_address ca1 ON ss.ss_addr_sk = ca1.ca_address_sk
    JOIN customer_demographics cd1 ON ss.ss_cdemo_sk = cd1.cd_demo_sk
    JOIN household_demographics hd1 ON ss.ss_hdemo_sk = hd1.hd_demo_sk
    WHERE d_ss.d_year = 2001
  ),
  cs AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_net_profit,
      d_cs.d_year,
      w.w_state,
      cc.cc_country,
      ca2.ca_state AS ca_state_bill,
      cd2.cd_gender,
      hd2.hd_income_band_sk
    FROM catalog_sales cs
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca2 ON cs.cs_bill_addr_sk = ca2.ca_address_sk
    JOIN customer_demographics cd2 ON cs.cs_bill_cdemo_sk = cd2.cd_demo_sk
    JOIN household_demographics hd2 ON cs.cs_bill_hdemo_sk = hd2.hd_demo_sk
    WHERE w.w_state = 'TX'
      AND cc.cc_country = 'USA'
      AND d_cs.d_year = 2001
  ),
  combined AS (
    SELECT
      COALESCE(ss.ss_sold_date_sk, cs.cs_sold_date_sk) AS sold_date_sk,
      COALESCE(ss.ss_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) AS total_net_profit,
      COALESCE(ss.d_year, cs.d_year) AS year,
      COALESCE(ss.ca_state, cs.ca_state_bill) AS state,
      CASE
        WHEN COALESCE(ss.ss_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) > 10000 THEN 'HIGH'
        WHEN COALESCE(ss.ss_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) > 1000  THEN 'MEDIUM'
        ELSE 'LOW'
      END AS profit_category
    FROM ss
    FULL OUTER JOIN cs ON ss.ss_sold_date_sk = cs.cs_sold_date_sk
  )
SELECT
  sold_date_sk,
  year,
  state,
  profit_category,
  total_net_profit,
  RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
  (SELECT AVG(total_net_profit) FROM combined) AS avg_profit
FROM combined
WHERE profit_category <> 'LOW'
EXCEPT
SELECT
  sold_date_sk,
  year,
  state,
  profit_category,
  total_net_profit,
  profit_rank,
  avg_profit
FROM (
  SELECT
    sold_date_sk,
    year,
    state,
    profit_category,
    total_net_profit,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
    (SELECT AVG(total_net_profit) FROM combined) AS avg_profit
  FROM combined
) low
WHERE profit_rank > 100
ORDER BY profit_rank
LIMIT 50
