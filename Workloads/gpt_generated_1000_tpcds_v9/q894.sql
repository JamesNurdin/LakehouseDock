WITH cat_ret AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS cat_return_amount,
        SUM(cr.cr_return_quantity) AS cat_return_qty
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)service')
    GROUP BY r.r_reason_sk, r.r_reason_desc
),
web_ret AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_desc,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(wr.wr_return_quantity) AS web_return_qty
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wsite.web_country = 'United States'
      AND wsite.web_rec_end_date > DATE '2000-01-01'
      AND wsite.web_name LIKE concat('%', substring(r.r_reason_desc, 1, 5), '%')
      AND regexp_like(r.r_reason_desc, '(?i)service')
    GROUP BY r.r_reason_sk, r.r_reason_desc
)
SELECT
    COALESCE(cat.r_reason_desc, web.r_reason_desc) AS reason_desc,
    cat.cat_return_amount,
    web.web_return_amount,
    COALESCE(cat.cat_return_amount, 0) + COALESCE(web.web_return_amount, 0) AS total_return_amount,
    CASE WHEN COALESCE(cat.cat_return_amount, 0) + COALESCE(web.web_return_amount, 0) > 10000 THEN 'High' ELSE 'Low' END AS return_level,
    ROW_NUMBER() OVER (ORDER BY COALESCE(cat.cat_return_amount, 0) + COALESCE(web.web_return_amount, 0) DESC) AS return_rank,
    (SELECT avg(p.p_cost) FROM promotion p) AS avg_promo_cost
FROM cat_ret cat
FULL OUTER JOIN web_ret web ON cat.r_reason_sk = web.r_reason_sk
LIMIT 100
