WITH filtered_returns AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_returned_date_sk,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wr.wr_reason_sk,
        wr.wr_returning_addr_sk,
        wr.wr_refunded_addr_sk
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 0
      AND wr.wr_returned_date_sk BETWEEN 2450000 AND 2455000
),
joined_data AS (
    SELECT
        fr.wr_item_sk,
        i.i_category,
        i.i_current_price,
        p.p_promo_id,
        p.p_promo_name,
        r.r_reason_desc,
        ca_ret.ca_city,
        ca_ret.ca_gmt_offset,
        inv.inv_quantity_on_hand,
        fr.wr_return_quantity,
        fr.wr_net_loss
    FROM filtered_returns fr
    JOIN item i ON fr.wr_item_sk = i.i_item_sk
    JOIN promotion p
        ON i.i_item_sk = p.p_item_sk
       AND fr.wr_returned_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    JOIN reason r ON fr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_ret ON fr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE p.p_discount_active = 'Y'
      AND ca_ret.ca_gmt_offset = -5.00
      AND i.i_current_price >= 100
      AND inv.inv_quantity_on_hand > 0
      AND i.i_category IS NOT NULL
)
SELECT
    promo_id,
    promo_name,
    reason_desc,
    city,
    category,
    total_net_loss,
    total_return_qty,
    avg_inventory_on_hand,
    RANK() OVER (PARTITION BY reason_desc ORDER BY total_net_loss DESC) AS loss_rank_by_reason
FROM (
    SELECT
        p_promo_id AS promo_id,
        p_promo_name AS promo_name,
        r_reason_desc AS reason_desc,
        ca_city AS city,
        i_category AS category,
        SUM(wr_net_loss) AS total_net_loss,
        SUM(wr_return_quantity) AS total_return_qty,
        AVG(inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM joined_data
    GROUP BY
        p_promo_id,
        p_promo_name,
        r_reason_desc,
        ca_city,
        i_category
    HAVING SUM(wr_net_loss) > 0
) agg
ORDER BY total_net_loss DESC
LIMIT 50
