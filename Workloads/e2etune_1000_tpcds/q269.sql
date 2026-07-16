WITH sales_agg AS (
    SELECT
        ds.d_year,
        ds.d_moy,
        i.i_category AS i_category,
        wsit.web_country,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN date_dim ds ON ws.ws_sold_date_sk = ds.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE ds.d_year = 2022
      AND p.p_discount_active = 'Y'
      AND i.i_brand_id IN (101, 202, 303)
      AND wsit.web_country = 'United States'
    GROUP BY ds.d_year, ds.d_moy, i.i_category, wsit.web_country
),
returns_agg AS (
    SELECT
        dr.d_year,
        dr.d_moy,
        i.i_category AS i_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE dr.d_year = 2022
      AND cr.cr_reason_sk IN (16, 17, 59)
    GROUP BY dr.d_year, dr.d_moy, i.i_category
)
SELECT
    s.d_year,
    s.d_moy,
    s.i_category,
    s.web_country,
    s.total_net_profit,
    s.total_quantity,
    s.avg_discount,
    s.order_cnt,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.return_cnt, 0) AS return_cnt,
    CASE WHEN s.total_net_profit <> 0 THEN COALESCE(r.total_return_amount, 0) / s.total_net_profit ELSE NULL END AS return_to_profit_ratio,
    RANK() OVER (PARTITION BY s.d_year, s.d_moy ORDER BY s.total_net_profit DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.d_year = r.d_year
 AND s.d_moy = r.d_moy
 AND s.i_category = r.i_category
ORDER BY s.d_year, s.d_moy, profit_rank
LIMIT 100
