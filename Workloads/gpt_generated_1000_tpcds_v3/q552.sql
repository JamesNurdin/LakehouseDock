WITH cs_agg AS (
    SELECT
        d_cs.d_date AS sales_date,
        SUM(cs.cs_net_profit) AS cs_total_profit,
        SUM(cs.cs_quantity) AS cs_total_quantity
    FROM catalog_sales cs
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE
        d_cs.d_year = 2000
        AND ca_bill.ca_location_type = 'apartment'
        AND cs.cs_quantity > 1
        AND d_ship.d_week_seq = 15
    GROUP BY d_cs.d_date
),
ss_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_tax_percentage,
        d_ss.d_date AS sales_date,
        d_closed.d_date AS closed_date,
        SUM(ss.ss_net_profit) AS ss_total_profit,
        SUM(ss.ss_quantity) AS ss_total_quantity
    FROM store_sales ss
    JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN customer_address ca_sales ON ss.ss_addr_sk = ca_sales.ca_address_sk
    WHERE
        d_ss.d_current_month = 'Y'
        AND s.s_tax_percentage BETWEEN 0.03 AND 0.07
        AND ca_sales.ca_location_type = 'apartment'
        AND ss.ss_quantity > 0
        AND d_closed.d_year = 2000
    GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name, s.s_tax_percentage, d_ss.d_date, d_closed.d_date
),
sr_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        d_sr.d_date AS return_date,
        SUM(sr.sr_net_loss) AS sr_total_loss,
        SUM(sr.sr_return_quantity) AS sr_total_quantity
    FROM store_returns sr
    JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN store_sales ss ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN customer_address ca_return ON sr.sr_addr_sk = ca_return.ca_address_sk
    WHERE
        d_sr.d_year = 2000
        AND ca_return.ca_location_type = 'apartment'
        AND sr.sr_return_quantity >= 0
    GROUP BY s.s_store_sk, s.s_store_id, d_sr.d_date
),
inv_agg AS (
    SELECT
        d_inv.d_date AS inv_date,
        SUM(i.inv_quantity_on_hand) AS inv_total_qty
    FROM inventory i
    JOIN date_dim d_inv ON i.inv_date_sk = d_inv.d_date_sk
    WHERE
        d_inv.d_year = 2000
        AND i.inv_quantity_on_hand > 100
    GROUP BY d_inv.d_date
)
SELECT DISTINCT
    ss.s_store_id,
    ss.s_store_name,
    ss.sales_date,
    ss.s_tax_percentage,
    cs.cs_total_profit,
    ss.ss_total_profit,
    COALESCE(sr.sr_total_loss, 0) AS sr_total_loss,
    (ss.ss_total_profit + COALESCE(cs.cs_total_profit, 0) - COALESCE(sr.sr_total_loss, 0)) AS total_net_profit,
    inv.inv_total_qty,
    RANK() OVER (
        PARTITION BY ss.sales_date
        ORDER BY (ss.ss_total_profit + COALESCE(cs.cs_total_profit, 0) - COALESCE(sr.sr_total_loss, 0)) DESC
    ) AS profit_rank
FROM ss_agg ss
LEFT JOIN cs_agg cs ON ss.sales_date = cs.sales_date
LEFT JOIN sr_agg sr ON ss.s_store_sk = sr.s_store_sk AND ss.sales_date = sr.return_date
LEFT JOIN inv_agg inv ON ss.sales_date = inv.inv_date
ORDER BY ss.sales_date DESC, profit_rank
LIMIT 100
