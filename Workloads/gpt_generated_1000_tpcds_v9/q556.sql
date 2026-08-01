WITH promo_items AS (
        SELECT DISTINCT p.p_item_sk
        FROM promotion p
        WHERE p.p_discount_active = 'Y'
    ),
    joined_data AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            i.i_item_id,
            i.i_brand,
            i.i_category,
            i.i_manufact,
            ca.ca_zip,
            c.c_customer_id,
            s.s_store_id,
            cc.cc_call_center_id,
            cp.cp_department,
            sm.sm_type,
            r.r_reason_desc,
            ws.web_name,
            p.p_promo_name,
            p.p_cost,
            sr.sr_return_amt,
            cr.cr_return_amount,
            wr.wr_return_amt,
            sr.sr_net_loss,
            cr.cr_net_loss,
            wr.wr_net_loss
        FROM date_dim d
        JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
        JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
        JOIN promotion p ON p.p_item_sk = i.i_item_sk
        WHERE d.d_year = 1999
          AND i.i_brand = 'Brand#23'
          AND ca.ca_zip = '90419'
          AND cp.cp_department = 'Sports'
          AND cc.cc_state = 'CA'
          AND i.i_item_sk IN (SELECT p_item_sk FROM promo_items)
    ),
    aggregated AS (
        SELECT
            d_year,
            i_brand,
            i_category,
            SUM(sr_return_amt) AS total_store_return,
            SUM(cr_return_amount) AS total_catalog_return,
            SUM(wr_return_amt) AS total_web_return,
            COUNT(DISTINCT c_customer_id) AS distinct_customers,
            AVG(p_cost) AS avg_promo_cost,
            MAX(sr_net_loss) AS max_store_net_loss,
            MIN(cr_net_loss) AS min_catalog_net_loss
        FROM joined_data
        GROUP BY d_year, i_brand, i_category
    )
SELECT
    d_year,
    i_brand,
    i_category,
    total_store_return,
    total_catalog_return,
    total_web_return,
    distinct_customers,
    avg_promo_cost,
    max_store_net_loss,
    min_catalog_net_loss,
    SUM(total_store_return + total_catalog_return + total_web_return) OVER (PARTITION BY d_year) AS yearly_total_return,
    RANK() OVER (ORDER BY total_store_return DESC) AS store_return_rank
FROM aggregated
ORDER BY total_store_return DESC
LIMIT 100
