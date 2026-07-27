WITH sales_returns AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_buy_potential,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        COUNT(DISTINCT cr.cr_order_number) AS return_transactions
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr
        ON i.i_item_sk = cr.cr_item_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN web_page wp
        ON c.c_customer_sk = wp.wp_customer_sk
    WHERE i.i_current_price > 20
      AND inv.inv_quantity_on_hand > 300
      AND wp.wp_type = 'product'
    GROUP BY i.i_item_id, i.i_item_desc, c.c_customer_id, cd.cd_gender, hd.hd_buy_potential
)
SELECT
    i_item_id,
    i_item_desc,
    cd_gender,
    hd_buy_potential,
    total_sales,
    total_returns,
    (total_sales - total_returns) AS net_amount,
    sales_transactions,
    return_transactions
FROM sales_returns
WHERE (total_sales - total_returns) > 1000
ORDER BY net_amount DESC
LIMIT 100
