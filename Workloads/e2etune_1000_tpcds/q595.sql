WITH inventory_agg AS (
    SELECT inv_item_sk, AVG(inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM inventory
    WHERE inv_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY inv_item_sk
),
returns_detail AS (
    SELECT
        ca.ca_state AS state,
        cr.cr_ship_mode_sk AS ship_mode,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_quantity AS return_qty,
        cr.cr_return_amount AS return_amt,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_tax AS return_tax,
        i.avg_inventory_on_hand
    FROM catalog_returns cr
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN inventory_agg i ON cr.cr_item_sk = i.inv_item_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2459999
),
returns_agg AS (
    SELECT
        state,
        ship_mode,
        SUM(return_amt) AS total_return_amount,
        SUM(return_qty) AS total_return_quantity,
        SUM(net_loss) AS total_net_loss,
        AVG(return_tax) AS avg_return_tax,
        AVG(avg_inventory_on_hand) AS avg_inventory_on_hand
    FROM returns_detail
    GROUP BY state, ship_mode
),
sales_agg AS (
    SELECT
        ca.ca_state AS state,
        cs.cs_ship_mode_sk AS ship_mode,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2459999
      AND ca.ca_state IN ('CA', 'TX', 'NY')
    GROUP BY ca.ca_state, cs.cs_ship_mode_sk
)
SELECT
    s.state,
    s.ship_mode,
    s.total_sales,
    s.total_profit,
    r.total_return_amount,
    r.total_return_quantity,
    r.total_net_loss,
    CASE WHEN s.total_quantity > 0 THEN r.total_return_quantity / s.total_quantity ELSE NULL END AS return_rate,
    r.avg_return_tax,
    r.avg_inventory_on_hand,
    RANK() OVER (ORDER BY s.total_profit DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r ON s.state = r.state AND s.ship_mode = r.ship_mode
ORDER BY s.total_profit DESC
LIMIT 100
