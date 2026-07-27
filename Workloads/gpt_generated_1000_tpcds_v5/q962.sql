WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt
    FROM catalog_sales cs
)
SELECT
    i.i_item_id,
    i.i_product_name,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_paid,
    cr.cr_return_amount,
    cr.cr_net_loss,
    wr.wr_return_amt,
    r.r_reason_desc,
    d_sold.d_year,
    p.p_promo_name,
    wp.wp_url,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY cr.cr_net_loss DESC) AS loss_rank,
    (SELECT avg(cr2.cr_net_loss) FROM catalog_returns cr2 WHERE cr2.cr_item_sk = i.i_item_sk) AS avg_item_loss
FROM catalog_sales cs
JOIN date_dim d_sold
  ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
     AND p.p_item_sk = i.i_item_sk
JOIN catalog_returns cr
  ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_item_sk = i.i_item_sk
JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
     AND wr.wr_returned_date_sk = d_return.d_date_sk
JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
     AND wp.wp_creation_date_sk = d_return.d_date_sk
WHERE d_sold.d_year = 2001
  AND cs.cs_quantity > 2
  AND p.p_cost > 5000
  AND cr.cr_return_amount > 100
  AND r.r_reason_desc LIKE '%size%'
ORDER BY cr.cr_net_loss DESC, loss_rank
LIMIT 100
