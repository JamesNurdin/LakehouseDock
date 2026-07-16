WITH hourly_page_sales AS (
    SELECT
        cs.cs_catalog_page_sk AS catalog_page_sk,
        t.t_hour AS t_hour,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS transaction_cnt
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 12 AND 17
      AND t.t_am_pm = 'PM'
    GROUP BY cs.cs_catalog_page_sk, t.t_hour
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    hps.t_hour,
    hps.total_sales,
    hps.total_discount,
    hps.total_profit,
    hps.transaction_cnt,
    hps.total_sales / NULLIF(hps.transaction_cnt, 0) AS avg_sales_per_tx,
    CASE WHEN hps.total_sales > 0 THEN hps.total_discount / hps.total_sales ELSE 0 END AS discount_rate,
    CASE WHEN hps.total_sales > 0 THEN hps.total_profit / hps.total_sales ELSE 0 END AS profit_margin
FROM hourly_page_sales hps
JOIN catalog_page cp
    ON hps.catalog_page_sk = cp.cp_catalog_page_sk
WHERE cp.cp_catalog_page_number IN (1, 2, 3)
  AND cp.cp_start_date_sk BETWEEN 2450800 AND 2451100
ORDER BY hps.total_sales DESC
LIMIT 100
