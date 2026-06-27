WITH catalog_sales_agg AS (
    SELECT
        p.p_promo_name AS p_promo_name,
        d.d_year AS d_year,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
        SUM(cs.cs_net_profit) AS total_catalog_profit
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY p.p_promo_name, d.d_year
),
web_sales_agg AS (
    SELECT
        p.p_promo_name AS p_promo_name,
        d.d_year AS d_year,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY p.p_promo_name, d.d_year
),
returns_agg AS (
    SELECT
        p.p_promo_name AS p_promo_name,
        d.d_year AS d_year,
        SUM(cr.cr_return_amount) AS total_returns_amount,
        SUM(cr.cr_net_loss) AS total_returns_loss
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY p.p_promo_name, d.d_year
)
SELECT
    COALESCE(cs.p_promo_name, ws.p_promo_name, r.p_promo_name) AS promo_name,
    COALESCE(cs.d_year, ws.d_year, r.d_year) AS year,
    cs.total_catalog_sales,
    ws.total_web_sales,
    r.total_returns_amount,
    (COALESCE(cs.total_catalog_sales, 0) + COALESCE(ws.total_web_sales, 0) - COALESCE(r.total_returns_amount, 0)) AS net_sales_amount,
    (COALESCE(cs.total_catalog_profit, 0) + COALESCE(ws.total_web_profit, 0) - COALESCE(r.total_returns_loss, 0)) AS net_profit
FROM catalog_sales_agg cs
FULL OUTER JOIN web_sales_agg ws
    ON cs.p_promo_name = ws.p_promo_name
    AND cs.d_year = ws.d_year
FULL OUTER JOIN returns_agg r
    ON COALESCE(cs.p_promo_name, ws.p_promo_name) = r.p_promo_name
    AND COALESCE(cs.d_year, ws.d_year) = r.d_year
ORDER BY promo_name, year
