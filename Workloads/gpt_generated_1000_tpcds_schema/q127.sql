WITH
    agg_cs AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_call_center_sk,
            cs.cs_ship_mode_sk,
            cs.cs_bill_customer_sk,
            SUM(cs.cs_ext_sales_price) AS total_sales,
            SUM(cs.cs_net_profit) AS total_profit,
            COUNT(*) AS sales_cnt,
            AVG(cs.cs_quantity) AS avg_qty
        FROM catalog_sales cs
        WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
          AND cs.cs_quantity > (
                SELECT AVG(cs2.cs_quantity)
                FROM catalog_sales cs2
                WHERE cs2.cs_sold_date_sk = 2450001
          )
        GROUP BY cs.cs_item_sk, cs.cs_call_center_sk, cs.cs_ship_mode_sk, cs.cs_bill_customer_sk
    ),
    item_returns AS (
        SELECT
            sr.sr_item_sk,
            SUM(sr.sr_return_amt) AS total_return_amt,
            SUM(sr.sr_net_loss) AS total_net_loss,
            COUNT(*) AS return_cnt,
            MAX(r.r_reason_desc) AS reason_desc
        FROM store_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        WHERE sr.sr_return_quantity > 0
        GROUP BY sr.sr_item_sk
    ),
    intersect_items AS (
        SELECT sr.sr_item_sk AS item_key FROM store_returns sr WHERE sr.sr_return_quantity > 0
        INTERSECT
        SELECT cs.cs_item_sk FROM catalog_sales cs WHERE cs.cs_quantity > 0
    ),
    filtered_promotions AS (
        SELECT p.p_promo_sk, p.p_item_sk, p.p_promo_name
        FROM promotion p
        WHERE p.p_channel_email = 'N'
          AND p.p_discount_active = 'N'
          AND p.p_promo_id NOT IN (
                SELECT p2.p_promo_id FROM promotion p2 WHERE p2.p_discount_active = 'Y'
          )
    )
SELECT
    cc.cc_name AS call_center_name,
    i.i_item_id,
    i.i_product_name,
    agg_cs.total_sales,
    agg_cs.total_profit,
    agg_cs.sales_cnt,
    ir.total_return_amt,
    ir.total_net_loss,
    ir.return_cnt,
    fp.p_promo_name,
    sm.sm_carrier,
    ir.reason_desc,
    ca.ca_city,
    cd.cd_gender,
    COUNT(DISTINCT cs_order.cs_order_number) AS distinct_orders
FROM agg_cs
JOIN call_center cc ON agg_cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i ON agg_cs.cs_item_sk = i.i_item_sk
JOIN filtered_promotions fp ON fp.p_item_sk = i.i_item_sk
JOIN ship_mode sm ON agg_cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c ON agg_cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN item_returns ir ON i.i_item_sk = ir.sr_item_sk
LEFT JOIN catalog_sales cs_order ON cs_order.cs_item_sk = i.i_item_sk
WHERE cc.cc_mkt_class LIKE '%National%'
  AND sm.sm_code = 'AIR'
  AND i.i_current_price > (
        SELECT AVG(i2.i_current_price)
        FROM item i2
        WHERE i2.i_brand_id = 1
  )
  AND i.i_item_sk IN (SELECT item_key FROM intersect_items)
  AND i.i_item_sk NOT IN (
        SELECT p3.p_item_sk FROM promotion p3 WHERE p3.p_discount_active = 'Y'
  )
GROUP BY
    cc.cc_name,
    i.i_item_id,
    i.i_product_name,
    agg_cs.total_sales,
    agg_cs.total_profit,
    agg_cs.sales_cnt,
    ir.total_return_amt,
    ir.total_net_loss,
    ir.return_cnt,
    fp.p_promo_name,
    sm.sm_carrier,
    ir.reason_desc,
    ca.ca_city,
    cd.cd_gender
ORDER BY agg_cs.total_sales DESC
LIMIT 100
