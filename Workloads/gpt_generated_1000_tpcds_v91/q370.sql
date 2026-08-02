WITH base AS (
    SELECT
        d.d_year,
        p.p_promo_name,
        cc.cc_name,
        cp.cp_department,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(sr.sr_return_amt_inc_tax) AS total_returns,
        CASE
            WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable'
            ELSE 'Loss'
        END AS profit_flag
    FROM date_dim d
    JOIN (
        SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)
    ) ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    WHERE
        d.d_date >= DATE '1998-01-01'
        AND d.d_date <= DATE '1998-12-31'
        AND p.p_discount_active = 'Y'
        AND p.p_response_target > 500
        AND cc.cc_gmt_offset BETWEEN -7.00 AND 0.00
        AND r.r_reason_desc <> ''
        AND cp.cp_type = 'PROMO'
        AND cp.cp_department IN ('Electronics', 'Furniture')
    GROUP BY GROUPING SETS (
        (d.d_year, p.p_promo_name, cc.cc_name, cp.cp_department),
        (d.d_year, p.p_promo_name, cc.cc_name),
        (d.d_year, p.p_promo_name),
        (d.d_year),
        ()
    )
)
SELECT
    COALESCE(b.d_year, 0) AS year,
    b.p_promo_name,
    b.cc_name,
    b.cp_department,
    b.total_store_sales,
    b.total_web_sales,
    b.total_returns,
    b.profit_flag,
    (SELECT MAX(total_store_sales) FROM base b2 WHERE b2.d_year = b.d_year) AS max_year_store_sales
FROM base b
WHERE b.total_store_sales > (
    SELECT AVG(total_store_sales) FROM base b3 WHERE b3.d_year = b.d_year
)
UNION DISTINCT
SELECT
    0 AS year,
    'ALL' AS p_promo_name,
    'ALL' AS cc_name,
    'ALL' AS cp_department,
    SUM(b.total_store_sales) AS total_store_sales,
    SUM(b.total_web_sales) AS total_web_sales,
    SUM(b.total_returns) AS total_returns,
    CASE WHEN SUM(b.total_store_sales) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
    NULL AS max_year_store_sales
FROM base b
HAVING SUM(b.total_store_sales) > 1000000
ORDER BY year DESC, total_store_sales DESC
LIMIT 100
