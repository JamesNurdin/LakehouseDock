WITH web_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        d_ws.d_date,
        SUM(ws.ws_net_paid)          AS web_net_paid,
        SUM(ws.ws_net_profit)        AS web_net_profit,
        COUNT(*)                     AS web_sales_cnt
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN customer_demographics cd_ws ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d_ws.d_year = 2001
      AND d_ws.d_month_seq BETWEEN 1200 AND 1210
      AND cd_ws.cd_gender = 'M'
      AND w.web_country = 'United States'
      AND w.web_open_date_sk = d_ws.d_date_sk
      AND w.web_name <> ''
    GROUP BY ws.ws_item_sk, ws.ws_web_site_sk, d_ws.d_date
),
catalog_agg AS (
    SELECT
        cs.cs_item_sk,
        d_cs.d_date,
        SUM(cs.cs_net_paid)          AS catalog_net_paid,
        SUM(cs.cs_net_profit)        AS catalog_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN customer_demographics cd_cs ON cs.cs_bill_cdemo_sk = cd_cs.cd_demo_sk
    WHERE d_cs.d_year = 2001
      AND d_cs.d_month_seq BETWEEN 1200 AND 1210
      AND cd_cs.cd_marital_status = 'M'
      AND cs.cs_quantity > 1
    GROUP BY cs.cs_item_sk, d_cs.d_date
),
return_agg AS (
    SELECT
        sr.sr_item_sk,
        d_sr.d_date,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*)               AS return_cnt
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    WHERE d_sr.d_year = 2001
      AND d_sr.d_holiday = 'N'
      AND cd_sr.cd_credit_rating = 'A'
      AND sr.sr_return_quantity > 0
    GROUP BY sr.sr_item_sk, d_sr.d_date
)
SELECT
    i.i_item_id,
    i.i_product_name,
    w.web_name,
    wa.d_date,
    wa.web_net_paid,
    wa.web_net_profit,
    wa.web_sales_cnt,
    ca.catalog_net_paid,
    ca.catalog_net_profit,
    ca.distinct_orders,
    ra.total_return_amt,
    ra.return_cnt,
    SUM(ca.catalog_net_profit) OVER (PARTITION BY i.i_item_id ORDER BY wa.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_catalog_profit,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY wa.web_net_profit DESC) AS rn
FROM web_agg wa
JOIN catalog_agg ca   ON wa.ws_item_sk = ca.cs_item_sk AND wa.d_date = ca.d_date
JOIN return_agg ra    ON wa.ws_item_sk = ra.sr_item_sk AND wa.d_date = ra.d_date
JOIN item i           ON wa.ws_item_sk = i.i_item_sk
JOIN web_site w       ON wa.ws_web_site_sk = w.web_site_sk
WHERE i.i_formulation = '8159007505thistle447'
  AND i.i_rec_start_date = DATE '1999-10-28'
  AND i.i_rec_end_date   = DATE '2001-10-26'
ORDER BY cumulative_catalog_profit DESC
LIMIT 100
