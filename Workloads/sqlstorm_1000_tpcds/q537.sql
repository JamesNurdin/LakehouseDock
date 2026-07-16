WITH store_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           'store' AS channel,
           i.i_category,
           SUM(ss.ss_net_profit) AS profit,
           SUM(ss.ss_quantity) AS quantity,
           AVG(ss.ss_ext_discount_amt) AS avg_discount,
           SUM(ss.ss_ext_sales_price) AS sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           'web' AS channel,
           i.i_category,
           SUM(ws.ws_net_profit) AS profit,
           SUM(ws.ws_quantity) AS quantity,
           AVG(ws.ws_ext_discount_amt) AS avg_discount,
           SUM(ws.ws_ext_sales_price) AS sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           'catalog' AS channel,
           i.i_category,
           SUM(cs.cs_net_profit) AS profit,
           SUM(cs.cs_quantity) AS quantity,
           AVG(cs.cs_ext_discount_amt) AS avg_discount,
           SUM(cs.cs_ext_sales_price) AS sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND p.p_discount_active = 'Y'
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
combined AS (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
    UNION ALL
    SELECT * FROM catalog_agg
)
SELECT *
FROM (
    SELECT
        d_year,
        d_month_seq,
        channel,
        i_category,
        profit,
        quantity,
        avg_discount,
        sales,
        RANK() OVER (PARTITION BY d_year ORDER BY profit DESC) AS profit_rank_year,
        AVG(profit) OVER (PARTITION BY channel ORDER BY d_month_seq ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS profit_3month_moving_avg
    FROM combined
) t
WHERE profit_rank_year <= 5
ORDER BY d_year, d_month_seq, profit DESC
