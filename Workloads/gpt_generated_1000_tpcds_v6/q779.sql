WITH store_sales_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        d.d_year AS year,
        SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk IN (
            SELECT ib.ib_income_band_sk
            FROM income_band ib
            WHERE ib.ib_lower_bound >= 100000
          )
      AND EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_promo_sk = ss.ss_promo_sk
              AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
          )
    GROUP BY ss.ss_item_sk, d.d_year
),
web_sales_agg AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        d.d_year AS year,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk IN (
            SELECT ib.ib_income_band_sk
            FROM income_band ib
            WHERE ib.ib_lower_bound >= 100000
          )
      AND EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_promo_sk = ws.ws_promo_sk
              AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
          )
    GROUP BY ws.ws_item_sk, d.d_year
)
SELECT item_sk, year, total_net_paid
FROM store_sales_agg
UNION ALL
SELECT item_sk, year, total_net_paid
FROM web_sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
