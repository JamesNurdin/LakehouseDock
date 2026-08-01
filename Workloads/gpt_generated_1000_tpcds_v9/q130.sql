WITH base AS (
    SELECT
        d.d_date,
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        i.i_category,
        i.i_class,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cr.cr_return_amount,
        cr.cr_store_credit,
        inv.inv_quantity_on_hand,
        ca.ca_state,
        wp.wp_image_count,
        wp.wp_max_ad_count
    FROM
        tpcds.date_dim d
        JOIN tpcds.store_sales ss
            ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN tpcds.item i
            ON ss.ss_item_sk = i.i_item_sk
        JOIN tpcds.store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = ss.ss_item_sk
        JOIN tpcds.catalog_sales cs
            ON cs.cs_item_sk = i.i_item_sk
            AND cs.cs_sold_date_sk = d.d_date_sk
        JOIN tpcds.catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
        JOIN tpcds.inventory inv
            ON inv.inv_item_sk = i.i_item_sk
            AND inv.inv_date_sk = d.d_date_sk
        JOIN tpcds.customer_address ca
            ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN tpcds.web_page wp
            ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE
        d.d_date >= DATE '2000-01-01'
        AND d.d_date < DATE '2001-01-01'
        AND ss.ss_quantity > 5
        AND i.i_current_price BETWEEN 10 AND 100
        AND sr.sr_return_quantity > 0
        AND cr.cr_store_credit > 0
        AND ca.ca_state = 'CA'
)
SELECT
    d_date,
    i_item_id,
    i_item_desc,
    i_category,
    i_class,
    total_sales,
    total_returns,
    net_profit,
    inventory_on_hand,
    avg_image_count,
    CASE
        WHEN total_returns > 0 THEN 'Has Returns'
        ELSE 'No Returns'
    END AS return_status,
    DENSE_RANK() OVER (PARTITION BY i_category ORDER BY net_profit DESC) AS category_profit_rank,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS sales_rank
FROM (
    SELECT
        d_date,
        d_date_sk,
        i_item_sk,
        i_item_id,
        i_item_desc,
        i_category,
        i_class,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cr_return_amount) AS total_returns,
        SUM(cs_net_profit) - SUM(cr_return_amount) AS net_profit,
        MAX(inv_quantity_on_hand) AS inventory_on_hand,
        AVG(wp_image_count) AS avg_image_count
    FROM base
    GROUP BY
        d_date,
        d_date_sk,
        i_item_sk,
        i_item_id,
        i_item_desc,
        i_category,
        i_class
) agg
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.inventory inv2
    WHERE inv2.inv_item_sk = agg.i_item_sk
      AND inv2.inv_date_sk > agg.d_date_sk
)
ORDER BY net_profit DESC
LIMIT 100
