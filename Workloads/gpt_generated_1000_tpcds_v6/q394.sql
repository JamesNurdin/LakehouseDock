WITH sales_data AS (
    SELECT
        wsite.web_name,
        d.d_year,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(p.p_cost) AS promo_cost,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
        (SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) - SUM(p.p_cost) - SUM(COALESCE(cr.cr_net_loss, 0))) AS total_profit
    FROM
        tpcds.date_dim d
        INNER JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        INNER JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
        LEFT  JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        LEFT  JOIN tpcds.catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT  JOIN tpcds.reason r ON cr.cr_reason_sk = r.r_reason_sk
        INNER JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        INNER JOIN tpcds.web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE
        d.d_year = 2001
        AND p.p_discount_active = 'Y'
        AND wsite.web_manager = 'Marshall Conner'
    GROUP BY
        ROLLUP (wsite.web_name, d.d_year)
)
SELECT
    web_name,
    d_year,
    store_net_paid,
    web_net_paid,
    promo_cost,
    total_return_loss,
    total_profit,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM
    sales_data
ORDER BY
    profit_rank
LIMIT 100
