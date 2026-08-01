WITH returns_agg AS (
    SELECT
        cr_order_number,
        SUM(cr_return_quantity) AS total_return_qty,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_count
    FROM catalog_returns
    WHERE cr_store_credit > 50
        AND cr_reversed_charge < 200
        AND cr_refunded_addr_sk IN (615378, 2257327, 1773122)
    GROUP BY cr_order_number
)
SELECT
    p.p_promo_name,
    ca.ca_state,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(ra.total_return_amount) AS total_returns,
    SUM(ra.total_net_loss) AS total_net_loss,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    SUM(cs.cs_quantity) AS total_quantity,
    AVG(cs.cs_sales_price) AS avg_sales_price
FROM returns_agg ra
JOIN catalog_sales cs
    ON ra.cr_order_number = cs.cs_order_number
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE p.p_channel_tv = 'N'
    AND p.p_response_target = 1
    AND p.p_channel_press = 'N'
    AND cs.cs_net_paid_inc_tax > 1000
    AND cs.cs_quantity >= 2
    AND ca.ca_state = 'CA'
    AND cd.cd_gender = 'M'
GROUP BY GROUPING SETS (
    (p.p_promo_name, ca.ca_state, cd.cd_gender, cd.cd_marital_status),
    (p.p_promo_name, ca.ca_state, cd.cd_gender),
    (p.p_promo_name, ca.ca_state),
    (p.p_promo_name),
    ()
)
ORDER BY total_sales DESC
LIMIT 100
