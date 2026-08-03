WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_net_paid,
        i.i_category,
        s.s_store_name,
        s.s_state,
        ca.ca_country,
        cc.cc_market_manager,
        cr.cr_return_tax,
        sr.sr_reversed_charge,
        inv.inv_quantity_on_hand,
        td.t_hour
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE
        s.s_state = 'CA'
        AND i.i_category = 'Electronics'
        AND ca.ca_country = 'United States'
        AND cc.cc_market_manager = 'John Doe'
        AND cr.cr_return_tax > 50
        AND sr.sr_reversed_charge < 10
        AND inv.inv_quantity_on_hand > 0
        AND td.t_hour BETWEEN 9 AND 17
        AND NOT EXISTS (
            SELECT 1 FROM catalog_returns cr2
            WHERE cr2.cr_item_sk = ss.ss_item_sk
              AND cr2.cr_returned_date_sk = ss.ss_sold_date_sk
        )
),
agg AS (
    SELECT
        s_store_name,
        s_state,
        i_category,
        MIN(ss_sold_date_sk) AS min_sold_date_sk,
        SUM(ss_net_paid) AS total_net_paid,
        AVG(ss_net_paid) AS avg_net_paid,
        COUNT(*) AS sales_cnt,
        MIN(ss_net_paid) AS min_net_paid,
        MAX(ss_net_paid) AS max_net_paid
    FROM base
    GROUP BY s_store_name, s_state, i_category
)
SELECT
    s_store_name,
    s_state,
    i_category,
    total_net_paid,
    avg_net_paid,
    sales_cnt,
    min_net_paid,
    max_net_paid,
    LAG(total_net_paid) OVER (PARTITION BY s_state ORDER BY min_sold_date_sk) AS lag_total_by_state
FROM agg
ORDER BY total_net_paid DESC
LIMIT 100
