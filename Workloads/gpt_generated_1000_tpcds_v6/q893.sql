WITH cte_a AS (
    SELECT
        cp.cp_catalog_page_id,
        d.d_year,
        cr.cr_return_amount,
        cr.cr_net_loss,
        ws.ws_ext_tax,
        ws.ws_net_profit,
        ws.ws_ext_ship_cost
    FROM catalog_page cp
    JOIN catalog_returns cr
        ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
           AND ws.ws_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2001
      AND ws.ws_ext_tax > 40
      AND hd.hd_vehicle_count >= 2
),
cte_b AS (
    SELECT
        cp.cp_catalog_page_id,
        d.d_year,
        cr.cr_return_amount,
        cr.cr_net_loss,
        ws.ws_ext_tax,
        ws.ws_net_profit,
        ws.ws_ext_ship_cost
    FROM catalog_page cp
    JOIN catalog_returns cr
        ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
           AND ws.ws_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2002
      AND ws.ws_ext_tax BETWEEN 10 AND 30
      AND hd.hd_vehicle_count = 1
),
combined AS (
    SELECT
        cp_catalog_page_id,
        d_year,
        cr_return_amount,
        cr_net_loss,
        ws_ext_tax,
        ws_net_profit,
        ws_ext_ship_cost
    FROM cte_a
    UNION ALL
    SELECT
        cp_catalog_page_id,
        d_year,
        cr_return_amount,
        cr_net_loss,
        ws_ext_tax,
        ws_net_profit,
        ws_ext_ship_cost
    FROM cte_b
),
aggregated AS (
    SELECT
        cp_catalog_page_id,
        d_year,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(ws_ext_tax) AS total_ext_tax,
        SUM(ws_ext_ship_cost) AS total_ship_cost
    FROM combined
    GROUP BY cp_catalog_page_id, d_year
)
SELECT
    cp_catalog_page_id,
    d_year,
    total_return_amount,
    total_net_profit,
    CASE WHEN total_net_loss > 150 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY d_year, profit_rank
LIMIT 100
