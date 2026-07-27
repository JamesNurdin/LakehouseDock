WITH store_agg AS (
    SELECT i.i_brand AS brand,
           'store_sales' AS metric_type,
           SUM(ss.ss_net_profit) AS total_amount
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451910 AND 2451919
    GROUP BY i.i_brand
),
return_agg AS (
    SELECT i.i_brand AS brand,
           'web_returns' AS metric_type,
           SUM(wr.wr_return_amt) AS total_amount
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451910 AND 2451919
      AND r.r_reason_desc = 'Package was damaged'
    GROUP BY i.i_brand
)
SELECT brand,
       metric_type,
       total_amount
FROM store_agg
UNION ALL
SELECT brand,
       metric_type,
       total_amount
FROM return_agg
ORDER BY total_amount DESC
LIMIT 100
