WITH returns_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_brand AS brand,
        td.t_hour AS hour_of_day,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN promotion p
        ON i.i_item_sk = p.p_item_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    WHERE cc.cc_state = 'CA'
      AND td.t_shift = 'first'
      AND i.i_brand = 'BrandX'
      AND inv.inv_quantity_on_hand > 0
      AND p.p_discount_active = 'Y'
    GROUP BY i.i_item_id, i.i_brand, td.t_hour
)
SELECT
    item_id,
    brand,
    AVG(total_net_loss) AS avg_net_loss_per_hour,
    SUM(return_cnt) AS total_returns,
    AVG(avg_return_amount) AS overall_avg_return_amount
FROM returns_agg
GROUP BY item_id, brand
HAVING AVG(total_net_loss) > 1000
ORDER BY avg_net_loss_per_hour DESC
LIMIT 100
