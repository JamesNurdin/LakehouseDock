WITH base AS (
    SELECT
        d.d_year,
        i.i_category,
        ws.ws_net_paid_inc_ship_tax,
        ss.ss_net_profit,
        wr.wr_net_loss,
        inv.inv_quantity_on_hand,
        sm.sm_carrier,
        w.w_state,
        ca_bill.ca_zip,
        r.r_reason_desc
    FROM date_dim d
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    FULL OUTER JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
       AND inv.inv_item_sk = ws.ws_item_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    LEFT JOIN web_site wsite
        ON wsite.web_open_date_sk = d.d_date_sk
    LEFT JOIN reason r
        ON r.r_reason_sk = wr.wr_reason_sk
    LEFT JOIN ship_mode sm
        ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    LEFT JOIN warehouse w
        ON w.w_warehouse_sk = ws.ws_warehouse_sk
    LEFT JOIN item i
        ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN customer_address ca_bill
        ON ca_bill.ca_address_sk = ws.ws_bill_addr_sk
    LEFT JOIN customer_address ca_ship
        ON ca_ship.ca_address_sk = ws.ws_ship_addr_sk
    WHERE d.d_year BETWEEN 2000 AND 2002                                   -- predicate 1
      AND i.i_brand = 'Brand#23'                                            -- predicate 2
      AND w.w_state = 'CA'                                                  -- predicate 3
      AND sm.sm_carrier = 'DHL'                                             -- predicate 4
      AND r.r_reason_desc LIKE '%damaged%'                                 -- predicate 5
      AND ca_bill.ca_zip = '90419'                                          -- predicate 6
),
agg1 AS (
    SELECT
        d_year,
        i_category,
        SUM(ws_net_paid_inc_ship_tax) AS total_net_paid,
        SUM(ss_net_profit) AS total_store_profit,
        SUM(wr_net_loss) AS total_return_loss,
        SUM(inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT ca_zip) AS distinct_zip_count
    FROM base
    GROUP BY d_year, i_category
)
SELECT DISTINCT
    d_year,
    i_category,
    total_net_paid,
    total_store_profit,
    total_return_loss,
    total_inventory,
    distinct_zip_count,
    total_net_paid / (SELECT AVG(total_net_paid) FROM agg1) AS net_paid_vs_avg
FROM agg1
WHERE total_net_paid > (
        SELECT MAX(total_net_paid)
        FROM agg1
        WHERE d_year = 2001
    )
GROUP BY d_year, i_category, total_net_paid, total_store_profit, total_return_loss, total_inventory, distinct_zip_count
HAVING COUNT(*) >= 2
ORDER BY total_net_paid DESC
LIMIT 100
