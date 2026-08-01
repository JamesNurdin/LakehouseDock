WITH ws_agg AS (
   SELECT
       ws.ws_item_sk,
       SUM(ws.ws_net_profit) AS total_profit,
       COUNT(*) AS sales_cnt
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2021
   GROUP BY ws.ws_item_sk
)
SELECT
    i.i_brand,
    i.i_color,
    CASE
        WHEN regexp_like(i.i_item_desc, '[0-9]{3}') THEN 'HasCode'
        ELSE 'NoCode'
    END AS code_flag,
    concat(i.i_brand, ' - ', i.i_color) AS brand_color,
    p.p_promo_name,
    ws_agg.total_profit,
    ws_agg.sales_cnt,
    CASE
        WHEN ws_agg.total_profit > (SELECT AVG(total_profit) FROM ws_agg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_relative,
    CASE
        WHEN ws_agg.total_profit > 0 THEN 'Profit'
        ELSE 'Loss'
    END AS profit_status,
    EXISTS (
        SELECT 1
        FROM store_returns sr
        JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
        WHERE sr.sr_item_sk = i.i_item_sk
          AND d_ret.d_year = 2020
    ) AS had_return_2020
FROM ws_agg
JOIN item i ON ws_agg.ws_item_sk = i.i_item_sk
JOIN promotion p ON p.p_item_sk = i.i_item_sk
WHERE p.p_promo_name LIKE '%Summer%'
  AND substring(i.i_color FROM 1 FOR 3) = 'Red'
ORDER BY ws_agg.total_profit DESC
LIMIT 100
