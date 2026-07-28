WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        ca.ca_state,
        SUM(cs.cs_net_paid)          AS catalog_sales_net,
        SUM(ws.ws_net_paid)          AS web_sales_net,
        SUM(cr.cr_net_loss)          AS returns_net_loss
    FROM item i
    INNER JOIN catalog_sales cs
        ON i.i_item_sk = cs.cs_item_sk
    INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    INNER JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    INNER JOIN web_sales ws
        ON i.i_item_sk = ws.ws_item_sk
    WHERE i.i_current_price BETWEEN 10 AND 100
      AND cs.cs_quantity > 5
      AND ws.ws_quantity > 2
      AND hd.hd_income_band_sk = 12
    GROUP BY i.i_item_sk, i.i_brand, ca.ca_state
)
SELECT
    brand,
    state,
    SUM(total_sales)          AS total_sales,
    SUM(total_returns)        AS total_returns,
    SUM(inventory_on_hand)    AS total_inventory_on_hand
FROM (
    SELECT
        sa.i_item_sk,
        sa.i_brand         AS brand,
        sa.ca_state        AS state,
        (sa.catalog_sales_net + sa.web_sales_net) AS total_sales,
        sa.returns_net_loss                AS total_returns,
        inv.total_on_hand                  AS inventory_on_hand
    FROM sales_agg sa
    CROSS JOIN LATERAL (
        SELECT SUM(inv_quantity_on_hand) AS total_on_hand
        FROM inventory inv
        WHERE inv.inv_item_sk = sa.i_item_sk
          AND inv.inv_date_sk IN (2451074, 2450843)
    ) inv
) t
GROUP BY ROLLUP (brand, state)
HAVING SUM(total_sales) > 1000
   AND SUM(inventory_on_hand) > 500
