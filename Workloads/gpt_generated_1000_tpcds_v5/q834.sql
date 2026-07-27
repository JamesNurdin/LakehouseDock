WITH base AS (
    SELECT
        d.d_year,
        ca.ca_state,
        w.w_city,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_net_loss,
        wr.wr_net_loss,
        inv.inv_quantity_on_hand,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND ca.ca_state = 'CA'
      AND w.w_city = 'Seattle'
),
agg AS (
    SELECT
        d_year,
        ca_state,
        w_city,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(COALESCE(sr_net_loss, 0)) AS total_store_return_loss,
        SUM(COALESCE(wr_net_loss, 0)) AS total_web_return_loss,
        AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
        COUNT(DISTINCT ss_ticket_number) AS unique_tickets
    FROM base
    GROUP BY ROLLUP(d_year, ca_state, w_city)
    HAVING SUM(ss_net_paid) > 10000
)
SELECT
    d_year,
    ca_state,
    w_city,
    total_net_paid,
    total_net_profit,
    total_store_return_loss,
    total_web_return_loss,
    avg_inventory_on_hand,
    unique_tickets,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS rn_yearly
FROM agg
ORDER BY d_year, ca_state, w_city
LIMIT 100
