WITH
    -- Sample a fraction of inventory and aggregate quantity on hand per item
    inventory_sample AS (
        SELECT inv_item_sk,
               inv_warehouse_sk,
               SUM(inv_quantity_on_hand) AS qty_on_hand
        FROM inventory TABLESAMPLE BERNOULLI (10)
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),

    -- Aggregate store channel data
    store_agg AS (
        SELECT
            d1.d_date               AS sales_date,
            s.s_store_name          AS store_name,
            p.p_promo_name          AS promo_name,
            SUM(ss.ss_ext_sales_price)                     AS total_sales,
            COALESCE(SUM(sr.sr_return_amt), 0)             AS total_returns,
            COALESCE(SUM(inv.qty_on_hand), 0)              AS inventory_qty
        FROM store_sales ss
        JOIN date_dim d1          ON ss.ss_sold_date_sk   = d1.d_date_sk
        JOIN time_dim t1          ON ss.ss_sold_time_sk   = t1.t_time_sk
        JOIN item i               ON ss.ss_item_sk        = i.i_item_sk
        JOIN customer c           ON ss.ss_customer_sk    = c.c_customer_sk
        JOIN customer_address ca  ON ss.ss_addr_sk        = ca.ca_address_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk   = cd.cd_demo_sk
        JOIN store s              ON ss.ss_store_sk       = s.s_store_sk
        JOIN promotion p          ON ss.ss_promo_sk       = p.p_promo_sk
        LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        LEFT JOIN reason r          ON sr.sr_reason_sk   = r.r_reason_sk
        LEFT JOIN inventory_sample inv ON ss.ss_item_sk = inv.inv_item_sk
        WHERE EXISTS (
            SELECT 1
            FROM web_returns wr
            JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
            WHERE wr.wr_refunded_customer_sk = ss.ss_customer_sk
              AND d_wr.d_date = d1.d_date
        )
        GROUP BY d1.d_date, s.s_store_name, p.p_promo_name, inv.qty_on_hand
    ),

    -- Aggregate web channel data
    web_agg AS (
        SELECT
            d2.d_date               AS sales_date,
            CAST(NULL AS varchar)   AS store_name,
            p2.p_promo_name         AS promo_name,
            SUM(ws.ws_ext_sales_price)                     AS total_sales,
            COALESCE(SUM(wr.wr_return_amt), 0)             AS total_returns,
            COALESCE(SUM(inv2.qty_on_hand), 0)             AS inventory_qty
        FROM web_sales ws
        JOIN date_dim d2          ON ws.ws_sold_date_sk = d2.d_date_sk
        JOIN time_dim t2          ON ws.ws_sold_time_sk = t2.t_time_sk
        JOIN item i2              ON ws.ws_item_sk     = i2.i_item_sk
        JOIN customer c_bill      ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
        JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN ship_mode sm        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN promotion p2        ON ws.ws_promo_sk    = p2.p_promo_sk
        LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
        LEFT JOIN reason r2       ON wr.wr_reason_sk   = r2.r_reason_sk
        LEFT JOIN inventory_sample inv2 ON ws.ws_item_sk = inv2.inv_item_sk
        WHERE EXISTS (
            SELECT 1
            FROM store_returns sr2
            JOIN date_dim d_sr2 ON sr2.sr_returned_date_sk = d_sr2.d_date_sk
            WHERE sr2.sr_customer_sk = ws.ws_bill_customer_sk
              AND d_sr2.d_date = d2.d_date
        )
        GROUP BY d2.d_date, p2.p_promo_name, inv2.qty_on_hand
    ),

    -- Union the two channel aggregates
    union_agg AS (
        SELECT DISTINCT sales_date, store_name, total_sales, total_returns, inventory_qty, promo_name
        FROM store_agg
        UNION DISTINCT
        SELECT DISTINCT sales_date, store_name, total_sales, total_returns, inventory_qty, promo_name
        FROM web_agg
    )
SELECT
    u.sales_date,
    u.store_name,
    u.total_sales,
    u.total_returns,
    u.inventory_qty,
    u.promo_name,
    RANK() OVER (PARTITION BY u.store_name ORDER BY u.total_sales DESC) AS sales_rank,
    (
        SELECT SUM(ws5.ws_ext_sales_price)
        FROM web_sales ws5
        JOIN date_dim d5 ON ws5.ws_sold_date_sk = d5.d_date_sk
        WHERE d5.d_date = u.sales_date
    ) AS total_web_sales_on_date
FROM union_agg u
WHERE EXISTS (
    SELECT 1
    FROM call_center cc
    JOIN date_dim d_cc ON cc.cc_closed_date_sk = d_cc.d_date_sk
    WHERE d_cc.d_date = u.sales_date
      AND cc.cc_country = 'United States'
)
ORDER BY u.sales_date DESC, sales_rank
LIMIT 100
