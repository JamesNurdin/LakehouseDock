WITH item_metrics AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_size,
        SUM(ss.ss_net_paid) AS sum_store_sales,
        SUM(ss.ss_net_profit) AS sum_store_profit,
        SUM(ss.ss_quantity) AS sum_store_quantity,
        SUM(sr.sr_return_amt) AS sum_store_returns,
        SUM(sr.sr_net_loss) AS sum_store_return_loss,
        SUM(cs.cs_net_paid) AS sum_catalog_sales,
        SUM(cs.cs_net_profit) AS sum_catalog_profit,
        SUM(cs.cs_quantity) AS sum_catalog_quantity,
        SUM(wr.wr_return_amt) AS sum_web_returns,
        SUM(wr.wr_net_loss) AS sum_web_return_loss,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand,
        SUM(p.p_cost) AS total_promo_cost,
        sm.sm_type AS ship_mode_type,
        ca.ca_state AS address_state,
        cd.cd_gender AS customer_gender,
        (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) - SUM(sr.sr_net_loss) - SUM(wr.wr_net_loss) - SUM(p.p_cost)) AS net_profit_estimate
    FROM
        item i
        LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
        LEFT JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
        LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
        LEFT JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk
        LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
        LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
        LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        LEFT JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE
        ss.ss_quantity > 1
        AND cs.cs_quantity > 0
        AND p.p_discount_active = 'Y'
        AND inv.inv_quantity_on_hand BETWEEN 100 AND 500
        AND i.i_category = 'Women'
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_size,
        sm.sm_type,
        ca.ca_state,
        cd.cd_gender
)
SELECT
    i_item_sk,
    i_item_id,
    i_category,
    i_class,
    i_brand,
    i_size,
    total_on_hand,
    sum_store_sales,
    sum_store_profit,
    sum_catalog_sales,
    sum_catalog_profit,
    sum_store_returns,
    sum_store_return_loss,
    sum_web_returns,
    sum_web_return_loss,
    total_promo_cost,
    ship_mode_type,
    address_state,
    customer_gender,
    net_profit_estimate,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY net_profit_estimate DESC) AS category_item_rank,
    RANK() OVER (ORDER BY net_profit_estimate DESC) AS global_profit_rank,
    SUM(net_profit_estimate) OVER (ORDER BY net_profit_estimate DESC ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS moving_sum_profit
FROM
    item_metrics
WHERE
    net_profit_estimate > 0
ORDER BY
    net_profit_estimate DESC
LIMIT 100
