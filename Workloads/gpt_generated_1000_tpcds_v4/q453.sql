WITH store_agg AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_store_qty,
        SUM(sr_net_loss) AS total_store_net_loss
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2450000 AND 2459999
      AND sr_return_quantity > 0
      AND sr_return_amt > 0
    GROUP BY sr_item_sk
)
SELECT
    i.i_category,
    SUM(sa.total_store_net_loss) AS total_store_net_loss,
    AVG(sa.total_store_net_loss) AS avg_store_net_loss,
    COUNT(DISTINCT i.i_item_sk) AS distinct_items,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount
FROM store_agg sa
JOIN item i
    ON sa.sr_item_sk = i.i_item_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN customer_address ca
    ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
WHERE i.i_manufact = 'barprically'
  AND p.p_discount_active = 'Y'
  AND ca.ca_state = 'CA'
  AND cd.cd_gender = 'M'
  AND p.p_start_date_sk >= 2450000
GROUP BY i.i_category
HAVING SUM(sa.total_store_net_loss) > 1000
ORDER BY total_store_net_loss DESC
LIMIT 10
