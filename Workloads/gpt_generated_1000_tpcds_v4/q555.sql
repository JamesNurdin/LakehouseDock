WITH returns_detail AS (
    SELECT DISTINCT
        ws.ws_order_number,
        ws.ws_bill_customer_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        ca.ca_city,
        ca.ca_state,
        sm.sm_carrier,
        w.w_warehouse_name,
        regexp_extract(w.w_warehouse_name, '^([A-Za-z]+)', 1) AS warehouse_prefix,
        substring(w.w_warehouse_name FROM 1 FOR 5) AS warehouse_prefix_5,
        regexp_like(ca.ca_city, '^San.*') AS city_starts_san,
        concat(CAST(ws.ws_order_number AS VARCHAR), '-', CAST(wr.wr_return_quantity AS VARCHAR)) AS order_return_key,
        t.t_hour
    FROM web_sales ws
    JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE regexp_like(ca.ca_city, '^San.*')
      AND sm.sm_carrier LIKE '%Express%'
)
SELECT
    rd.ca_city,
    rd.ca_state,
    rd.warehouse_prefix,
    SUM(rd.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    RANK() OVER (PARTITION BY rd.ca_state ORDER BY SUM(rd.wr_net_loss) DESC) AS loss_rank_state
FROM returns_detail rd
GROUP BY
    rd.ca_city,
    rd.ca_state,
    rd.warehouse_prefix
HAVING COUNT(*) > 1
ORDER BY total_net_loss DESC
LIMIT 100
