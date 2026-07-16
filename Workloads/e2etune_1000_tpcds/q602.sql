WITH sales_agg AS (
    SELECT
        i.i_category,
        ca.ca_state,
        hd.hd_buy_potential,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2451500
    GROUP BY i.i_category, ca.ca_state, hd.hd_buy_potential
),
returns_agg AS (
    SELECT
        i.i_category,
        ca.ca_state,
        hd.hd_buy_potential,
        SUM(cr.cr_net_loss) AS total_return_loss,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2451500
    GROUP BY i.i_category, ca.ca_state, hd.hd_buy_potential
)
SELECT
    s.i_category,
    s.ca_state,
    s.hd_buy_potential,
    s.total_sales,
    r.total_return_loss,
    (s.total_sales - COALESCE(r.total_return_loss, 0)) AS net_sales_after_returns,
    (s.total_profit - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
    s.total_quantity_sold,
    r.total_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY s.ca_state ORDER BY (s.total_sales - COALESCE(r.total_return_loss, 0)) DESC) AS rn_state_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.i_category = r.i_category
    AND s.ca_state = r.ca_state
    AND s.hd_buy_potential = r.hd_buy_potential
WHERE (s.total_sales - COALESCE(r.total_return_loss, 0)) > 10000
ORDER BY net_sales_after_returns DESC
LIMIT 100
