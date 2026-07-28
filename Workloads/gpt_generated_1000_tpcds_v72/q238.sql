WITH base AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_state,
        ca.ca_city,
        hd.hd_buy_potential,
        td.t_hour,
        ss.ss_customer_sk,
        ss.ss_net_paid,
        ss.ss_quantity,
        ss.ss_sold_time_sk,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        ws.ws_net_paid_inc_ship,
        ws.ws_order_number,
        ws.ws_ext_ship_cost,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_returned_time_sk = td.t_time_sk
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND s.s_state = 'CA'
        AND w.w_state = 'CA'
        AND hd.hd_buy_potential = '1001-5000'
        AND ss.ss_quantity > 5
        AND ws.ws_net_paid_inc_ship > 2000
),
agg AS (
    SELECT
        b.s_store_id,
        b.s_state,
        b.ca_city,
        b.hd_buy_potential,
        b.t_hour,
        COUNT(DISTINCT b.ss_customer_sk) AS unique_customers,
        SUM(b.ss_net_paid) AS total_store_sales,
        SUM(b.ws_net_paid_inc_ship) AS total_web_sales,
        AVG(b.sr_return_amt) AS avg_store_return_amt,
        SUM(COALESCE(b.sr_return_quantity, 0)) AS total_store_return_qty,
        COUNT(DISTINCT b.ws_order_number) AS web_orders,
        SUM(b.ws_ext_ship_cost) AS total_web_ship_cost,
        SUM(COALESCE(b.wr_return_amt, 0)) AS total_web_return_amt,
        SUM(COALESCE(b.wr_return_quantity, 0)) AS total_web_return_qty,
        b.s_store_sk
    FROM base b
    GROUP BY
        b.s_store_id,
        b.s_state,
        b.ca_city,
        b.hd_buy_potential,
        b.t_hour,
        b.s_store_sk
)
SELECT
    a.s_store_id,
    a.s_state,
    a.ca_city,
    a.hd_buy_potential,
    a.t_hour,
    a.unique_customers,
    a.total_store_sales,
    a.total_web_sales,
    a.avg_store_return_amt,
    a.total_store_return_qty,
    a.web_orders,
    a.total_web_ship_cost,
    a.total_web_return_amt,
    a.total_web_return_qty,
    (SELECT MAX(ss2.ss_net_paid)
     FROM store_sales ss2
     WHERE ss2.ss_store_sk = a.s_store_sk) AS max_store_sale_net_paid,
    (SELECT COUNT(*)
     FROM store_returns sr2
     WHERE sr2.sr_store_sk = a.s_store_sk
       AND sr2.sr_return_amt > 500) AS high_value_store_returns,
    RANK() OVER (PARTITION BY a.s_state ORDER BY a.total_store_sales DESC) AS state_sales_rank
FROM agg a
ORDER BY a.total_store_sales DESC
LIMIT 100
