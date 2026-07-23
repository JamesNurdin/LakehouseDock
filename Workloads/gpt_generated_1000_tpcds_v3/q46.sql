WITH store_fact AS (
    SELECT
        ss.ss_sold_date_sk,
        td.t_hour,
        hd.hd_income_band_sk,
        ca.ca_state,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr ON ss.ss_item_sk = sr.sr_item_sk AND ss.ss_ticket_number = sr.sr_ticket_number
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450005
      AND ss.ss_quantity > 5
      AND ca.ca_state = 'TX'
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_item_sk = ss.ss_item_sk
            AND sr2.sr_return_amt > 500
      )
),
catalog_fact AS (
    SELECT
        cs.cs_sold_date_sk,
        td.t_hour,
        hd.hd_income_band_sk,
        ca.ca_state,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        w.w_warehouse_name
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr ON cs.cs_item_sk = cr.cr_item_sk AND cs.cs_order_number = cr.cr_order_number
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450005
      AND cs.cs_quantity > 5
      AND ca.ca_state = 'TX'
)
SELECT
    source,
    date_sk,
    t_hour,
    hd_income_band_sk,
    ca_state,
    total_quantity,
    total_net_paid,
    total_net_profit,
    total_return_quantity,
    total_return_amount,
    transaction_count,
    profit_flag
FROM (
    SELECT
        'store' AS source,
        ss_sold_date_sk AS date_sk,
        t_hour,
        hd_income_band_sk,
        ca_state,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_return_quantity,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_amount,
        COUNT(*) AS transaction_count,
        CASE WHEN SUM(ss_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
    FROM store_fact
    GROUP BY ss_sold_date_sk, t_hour, hd_income_band_sk, ca_state
    HAVING SUM(ss_quantity) > 10
    UNION ALL
    SELECT
        'catalog' AS source,
        cs_sold_date_sk AS date_sk,
        t_hour,
        hd_income_band_sk,
        ca_state,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(COALESCE(cr_return_quantity, 0)) AS total_return_quantity,
        SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
        COUNT(*) AS transaction_count,
        CASE WHEN SUM(cs_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
    FROM catalog_fact
    GROUP BY cs_sold_date_sk, t_hour, hd_income_band_sk, ca_state
    HAVING SUM(cs_quantity) > 10
) combined
ORDER BY date_sk, source
LIMIT 100
