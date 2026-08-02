WITH inv_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM
        inventory TABLESAMPLE BERNOULLI (10)
    GROUP BY
        inv_warehouse_sk,
        inv_date_sk
),
sales_agg AS (
    SELECT
        d.d_year,
        d.d_date,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        cd.cd_gender,
        inv_agg.total_qty_on_hand,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) AS total_net_paid
    FROM
        date_dim d
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
        JOIN inv_agg ON inv_agg.inv_date_sk = d.d_date_sk
                     AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        d.d_year = 2001
        AND cd.cd_marital_status = 'M'
        AND w.w_state = 'CA'
        AND inv_agg.total_qty_on_hand > 200
    GROUP BY
        d.d_year,
        d.d_date,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        cd.cd_gender,
        inv_agg.total_qty_on_hand
    HAVING
        SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) > 10000
)
SELECT
    d_year,
    d_date,
    w_warehouse_name,
    cd_gender,
    CASE WHEN total_net_paid > 20000 THEN 'High' ELSE 'Low' END AS profit_category,
    total_qty_on_hand,
    total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS profit_rank,
    SUM(total_net_paid) OVER (PARTITION BY w_warehouse_sk ORDER BY d_date ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) AS rolling_30day_net_paid
FROM
    sales_agg
ORDER BY
    profit_rank
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
