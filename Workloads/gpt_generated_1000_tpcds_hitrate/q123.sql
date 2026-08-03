/*
Goal: Compute the total net profit (catalog + web – returns) by catalog page, ship mode, warehouse and hour of day, using a rich set of filters. The query first aggregates across multiple grouping sets, then filters groups that have at least one high‑loss return (net loss > 1000) and aggregates again using grouping sets. Results are ordered by profit and paginated.
*/
WITH base AS (
    SELECT
        cp.cp_catalog_page_number                                   AS catalog_page_number,
        sm.sm_type                                                  AS ship_mode_type,
        w.w_warehouse_name                                          AS warehouse_name,
        t.t_hour                                                    AS hour_of_day,
        t.t_time_sk                                                 AS time_sk,
        SUM(cs.cs_net_profit)                                      AS sum_catalog_profit,
        SUM(ws.ws_net_profit)                                      AS sum_web_profit,
        SUM(sr.sr_net_loss)                                        AS sum_return_loss,
        COUNT(*)                                                   AS txn_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode   sm       ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse    w       ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN time_dim    t       ON cs.cs_sold_time_sk   = t.t_time_sk
    JOIN promotion   p       ON cs.cs_promo_sk       = p.p_promo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    -- web sales share the same time dimension and other dimensions
    JOIN web_sales ws         ON ws.ws_sold_time_sk   = t.t_time_sk
    JOIN ship_mode   sm_ws   ON ws.ws_ship_mode_sk   = sm.sm_ship_mode_sk   -- same ship_mode table, same alias works
    JOIN warehouse    w_ws   ON ws.ws_warehouse_sk   = w.w_warehouse_sk
    JOIN promotion   p_ws   ON ws.ws_promo_sk       = p.p_promo_sk
    -- store returns share the same time dimension and have their own reason & address
    JOIN store_returns sr    ON sr.sr_return_time_sk = t.t_time_sk
    JOIN reason       r       ON sr.sr_reason_sk      = r.r_reason_sk
    JOIN customer_address ca_sr ON sr.sr_addr_sk    = ca_sr.ca_address_sk
    JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    WHERE cp.cp_catalog_page_number > 5                           -- predicate 1
      AND sm.sm_type = 'Air'                                      -- predicate 2
      AND w.w_state = 'CA'                                        -- predicate 3
      AND p.p_channel_dmail = 'Y'                                 -- predicate 4
      AND r.r_reason_desc = 'Damaged'                             -- predicate 5
      AND t.t_hour BETWEEN 9 AND 17                               -- predicate 6
      AND hd_bill.hd_vehicle_count > 1                            -- predicate 7
    GROUP BY GROUPING SETS (
        (cp.cp_catalog_page_number, sm.sm_type, w.w_warehouse_name, t.t_hour, t.t_time_sk),
        (cp.cp_catalog_page_number, sm.sm_type, w.w_warehouse_name),
        (cp.cp_catalog_page_number, sm.sm_type),
        (cp.cp_catalog_page_number),
        ()
    )
)
SELECT
    catalog_page_number,
    ship_mode_type,
    warehouse_name,
    hour_of_day,
    SUM(total_profit)               AS total_profit,
    AVG(txn_cnt)                    AS avg_txn_cnt
FROM (
    SELECT
        catalog_page_number,
        ship_mode_type,
        warehouse_name,
        hour_of_day,
        time_sk,
        (sum_catalog_profit + sum_web_profit - sum_return_loss) AS total_profit,
        txn_cnt
    FROM base
) b
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    WHERE sr2.sr_return_time_sk = b.time_sk
      AND sr2.sr_net_loss > 1000
)
GROUP BY GROUPING SETS (
    (catalog_page_number, ship_mode_type, warehouse_name, hour_of_day),
    (catalog_page_number, ship_mode_type, warehouse_name),
    (catalog_page_number, ship_mode_type),
    (catalog_page_number),
    ()
)
ORDER BY total_profit DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
