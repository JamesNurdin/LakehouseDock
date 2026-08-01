WITH base_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        d_sales.d_year,
        d_sales.d_month_seq,
        cs.cs_order_number,
        cs.cs_item_sk,
        i.i_item_id,
        i.i_category,
        cs.cs_net_profit,
        cs.cs_net_paid,
        cd.cd_gender,
        inv.inv_quantity_on_hand,
        s.s_store_id,
        s.s_tax_percentage,
        cr.cr_net_loss,
        cr.cr_refunded_cash
    FROM catalog_sales cs
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d_sales.d_date_sk
        AND inv.inv_item_sk = cs.cs_item_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d_sales.d_date_sk
    WHERE d_sales.d_year = 2001
      AND i.i_category = 'Sports'
      AND cd.cd_gender = 'F'
      AND inv.inv_quantity_on_hand > 0
      AND s.s_tax_percentage < 0.08
)
SELECT
    bs.d_year,
    bs.d_month_seq,
    bs.s_store_id,
    bs.i_item_id,
    bs.cs_order_number,
    (bs.cs_net_profit - COALESCE(bs.cr_net_loss, 0)) AS net_profit_after_returns,
    ROW_NUMBER() OVER (PARTITION BY bs.s_store_id ORDER BY (bs.cs_net_profit - COALESCE(bs.cr_net_loss, 0)) DESC) AS profit_rank,
    CASE WHEN (
        SELECT COALESCE(SUM(cr2.cr_refunded_cash), 0)
        FROM catalog_returns cr2
        WHERE cr2.cr_order_number = bs.cs_order_number
    ) > 0 THEN 'Returned' ELSE 'No Return' END AS return_flag
FROM base_sales bs
ORDER BY net_profit_after_returns DESC
LIMIT 100
