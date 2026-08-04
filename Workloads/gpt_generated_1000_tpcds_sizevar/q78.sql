WITH joined_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        i.i_item_id,
        i.i_category,
        i.i_class,
        i.i_current_price,
        cd.cd_gender,
        cd.cd_marital_status,
        cs.cs_net_paid_inc_ship,
        cr.cr_return_amount,
        cc.cc_name,
        inv.inv_quantity_on_hand,
        wr.wr_return_amt,
        ss.ss_quantity,
        ss.ss_list_price
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
                         AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                            AND cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                         AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE inv.inv_quantity_on_hand > 800
      AND i.i_category = 'Music'
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
),
expanded AS (
    SELECT jd.*, unnest_val
    FROM joined_data jd
    CROSS JOIN UNNEST(ARRAY[jd.ss_quantity, jd.ss_list_price]) AS t(unnest_val)
)
SELECT
    cat,
    cls,
    total_net_paid,
    total_return_amount,
    distinct_tickets,
    RANK() OVER (ORDER BY total_net_paid DESC) AS net_paid_rank
FROM (
    SELECT
        i_category AS cat,
        i_class AS cls,
        SUM(cs_net_paid_inc_ship) AS total_net_paid,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets
    FROM expanded
    GROUP BY ROLLUP(i_category, i_class)
) agg
UNION DISTINCT
SELECT
    cat,
    cls,
    total_net_paid,
    total_return_amount,
    distinct_tickets,
    RANK() OVER (ORDER BY total_net_paid DESC) AS net_paid_rank
FROM (
    SELECT
        i_category AS cat,
        i_class AS cls,
        SUM(cs_net_paid_inc_ship) AS total_net_paid,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets
    FROM expanded
    WHERE i_category = 'Women'
    GROUP BY ROLLUP(i_category, i_class)
) agg_w
ORDER BY cat, cls
LIMIT 100
