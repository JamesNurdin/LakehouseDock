WITH sampled_ws AS (
    SELECT *
    FROM web_sales TABLESAMPLE BERNOULLI (10)
    WHERE ws_sold_date_sk IS NOT NULL
),
large_orders AS (
    SELECT DISTINCT ws_bill_customer_sk
    FROM web_sales
    WHERE ws_net_paid > 10000
),
joined AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        i.i_item_id,
        i.i_category,
        d.d_year,
        ws.ws_net_paid,
        ws.ws_ext_discount_amt,
        ws.ws_ext_ship_cost,
        w.w_warehouse_name,
        ws.ws_order_number,
        cc.cc_name,
        ca.ca_city,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_item_sk,
        ws.ws_web_site_sk
    FROM sampled_ws ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_item_sk = i.i_item_sk
        AND ss.ss_customer_sk = c.c_customer_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE
        d.d_year = 2001
        AND i.i_category = 'Sports'
        AND site.web_manager = 'Peter Cassidy'
        AND cc.cc_state = 'CA'
        AND t.t_hour BETWEEN 8 AND 12
        AND c.c_customer_sk NOT IN (SELECT ws_bill_customer_sk FROM large_orders)
)
SELECT DISTINCT
    c_customer_sk,
    c_first_name,
    c_last_name,
    i_item_id,
    i_category,
    d_year,
    ws_net_paid,
    ws_ext_discount_amt,
    ws_ext_ship_cost,
    w_warehouse_name,
    cc_name,
    ca_city,
    cd_gender,
    hd_income_band_sk,
    RANK() OVER (PARTITION BY d_year ORDER BY ws_net_paid DESC) AS yearly_sales_rank,
    SUM(ws_net_paid) OVER (PARTITION BY c_customer_sk ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_customer_sales
FROM joined
ORDER BY yearly_sales_rank, ws_net_paid DESC
LIMIT 100
