WITH
sales_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        i.i_product_name,
        i.i_category,
        i.i_brand,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(*) AS sales_txn,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND p.p_discount_active = 'Y'
      AND ca.ca_state = 'CA'
      AND ib.ib_lower_bound >= 50000
    GROUP BY cs.cs_sold_date_sk, cs.cs_item_sk, d.d_date, d.d_year, d.d_month_seq,
             i.i_product_name, i.i_category, i.i_brand
),
store_ret_agg AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        SUM(sr.sr_net_loss) AS total_store_net_loss,
        COUNT(*) AS store_return_txn
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND r.r_reason_id = 'AAAAAAAABAAAAAAA'
      AND ca.ca_state = 'CA'
      AND ib.ib_lower_bound >= 50000
    GROUP BY sr.sr_returned_date_sk, sr.sr_item_sk, d.d_date, d.d_year, d.d_month_seq
),
web_ret_agg AS (
    SELECT
        wr.wr_returned_date_sk,
        wr.wr_item_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        COUNT(*) AS web_return_txn
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND wp.wp_max_ad_count > 0
      AND r.r_reason_desc LIKE '%did not%'
    GROUP BY wr.wr_returned_date_sk, wr.wr_item_sk, d.d_date, d.d_year, d.d_month_seq
),
inventory_agg AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY inv.inv_date_sk, inv.inv_item_sk, d.d_date, d.d_year, d.d_month_seq
),
reason_word_exp AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_returned_date_sk,
        w AS reason_word
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    CROSS JOIN UNNEST(split(r.r_reason_desc, ' ')) AS t(w)
),
combined AS (
    SELECT
        s.cs_sold_date_sk AS date_sk,
        s.cs_item_sk,
        s.d_date,
        s.d_year,
        s.d_month_seq,
        s.i_product_name,
        s.i_category,
        s.i_brand,
        s.total_sales,
        s.total_net_profit,
        s.total_quantity,
        s.sales_txn,
        COALESCE(st.total_store_return_amt, 0) AS total_store_return_amt,
        COALESCE(st.total_store_net_loss, 0) AS total_store_net_loss,
        COALESCE(st.store_return_txn, 0) AS store_return_txn,
        COALESCE(wr.total_web_return_amt, 0) AS total_web_return_amt,
        COALESCE(wr.total_web_net_loss, 0) AS total_web_net_loss,
        COALESCE(wr.web_return_txn, 0) AS web_return_txn,
        COALESCE(inv.total_inventory_qty, 0) AS total_inventory_qty,
        ws.web_name,
        ws.web_gmt_offset
    FROM sales_agg s
    LEFT JOIN store_ret_agg st
        ON s.cs_sold_date_sk = st.sr_returned_date_sk
       AND s.cs_item_sk = st.sr_item_sk
    LEFT JOIN web_ret_agg wr
        ON s.cs_sold_date_sk = wr.wr_returned_date_sk
       AND s.cs_item_sk = wr.wr_item_sk
    LEFT JOIN inventory_agg inv
        ON s.cs_sold_date_sk = inv.inv_date_sk
       AND s.cs_item_sk = inv.inv_item_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = s.cs_sold_date_sk
)
SELECT
    c.d_date,
    c.i_product_name,
    c.i_category,
    c.i_brand,
    c.d_year,
    c.d_month_seq,
    c.total_sales,
    c.total_store_return_amt,
    c.total_web_return_amt,
    c.total_inventory_qty,
    (c.total_net_profit - c.total_store_net_loss - c.total_web_net_loss) AS net_margin,
    c.sales_txn,
    c.store_return_txn,
    c.web_return_txn,
    c.web_name,
    c.web_gmt_offset,
    ROW_NUMBER() OVER (PARTITION BY c.d_date ORDER BY c.total_sales DESC) AS sales_rank_by_date,
    RANK() OVER (PARTITION BY c.d_year ORDER BY (c.total_net_profit - c.total_store_net_loss - c.total_web_net_loss) DESC) AS net_margin_yearly_rank,
    AVG(c.total_quantity) OVER (PARTITION BY c.i_category ORDER BY c.d_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_qty_7d,
    (SELECT AVG(s2.total_net_profit) FROM sales_agg s2 WHERE s2.cs_item_sk = c.cs_item_sk) AS avg_product_net_profit,
    rw.reason_word,
    COUNT(rw.reason_word) OVER (PARTITION BY c.i_product_name) AS reason_word_cnt
FROM combined c
LEFT JOIN reason_word_exp rw
    ON c.cs_item_sk = rw.sr_item_sk
   AND c.date_sk = rw.sr_returned_date_sk
WHERE c.total_sales > 0
  AND c.total_quantity > 0
  AND c.d_year = 2001
  AND c.i_category = 'Sports'
  AND c.web_name IS NOT NULL
GROUP BY c.d_date,
         c.i_product_name,
         c.i_category,
         c.i_brand,
         c.d_year,
         c.d_month_seq,
         c.total_sales,
         c.total_store_return_amt,
         c.total_web_return_amt,
         c.total_inventory_qty,
         c.total_net_profit,
         c.total_store_net_loss,
         c.total_web_net_loss,
         c.sales_txn,
         c.store_return_txn,
         c.web_return_txn,
         c.web_name,
         c.web_gmt_offset,
         c.cs_item_sk,
         c.total_quantity,
         c.date_sk,
         rw.reason_word
HAVING MIN(c.total_sales) > 10000
ORDER BY c.d_date DESC, net_margin DESC
LIMIT 100
