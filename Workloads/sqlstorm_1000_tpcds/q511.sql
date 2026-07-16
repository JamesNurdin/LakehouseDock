WITH
    sales_events AS (
        SELECT
            cs.cs_sold_date_sk AS date_sk,
            cs.cs_bill_customer_sk AS cust_sk,
            cs.cs_call_center_sk AS channel_sk,
            cs.cs_item_sk AS item_sk,
            cs.cs_order_number AS order_number,
            cs.cs_quantity AS quantity,
            cs.cs_net_paid AS net_paid,
            cs.cs_net_profit AS net_profit,
            cs.cs_ext_sales_price AS ext_sales_price,
            cs.cs_ext_discount_amt AS ext_discount_amt,
            cs.cs_ext_ship_cost AS ext_ship_cost,
            cs.cs_coupon_amt AS coupon_amt,
            d.d_year AS d_year,
            d.d_month_seq AS d_month_seq,
            i.i_category AS i_category,
            i.i_brand AS i_brand,
            p.p_promo_id AS promo_id,
            c.c_first_name AS first_name,
            c.c_last_name AS last_name,
            cd.cd_gender AS gender,
            cc.cc_name AS store_name,
            CAST(NULL AS varchar) AS web_url
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        LEFT JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        WHERE d.d_year BETWEEN 1999 AND 2001
          AND cs.cs_net_profit IS NOT NULL
    ),
    web_events AS (
        SELECT
            ws.ws_sold_date_sk AS date_sk,
            ws.ws_bill_customer_sk AS cust_sk,
            ws.ws_web_page_sk AS channel_sk,
            ws.ws_item_sk AS item_sk,
            ws.ws_order_number AS order_number,
            ws.ws_quantity AS quantity,
            ws.ws_net_paid AS net_paid,
            ws.ws_net_profit AS net_profit,
            ws.ws_ext_sales_price AS ext_sales_price,
            ws.ws_ext_discount_amt AS ext_discount_amt,
            ws.ws_ext_ship_cost AS ext_ship_cost,
            ws.ws_coupon_amt AS coupon_amt,
            d.d_year AS d_year,
            d.d_month_seq AS d_month_seq,
            i.i_category AS i_category,
            i.i_brand AS i_brand,
            p.p_promo_id AS promo_id,
            c.c_first_name AS first_name,
            c.c_last_name AS last_name,
            cd.cd_gender AS gender,
            CAST(NULL AS varchar) AS store_name,
            wp.wp_url AS web_url
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        WHERE d.d_year BETWEEN 1999 AND 2001
          AND ws.ws_net_profit IS NOT NULL
    ),
    combined_sales AS (
        SELECT * FROM sales_events
        UNION ALL
        SELECT * FROM web_events
    ),
    returns_catalog AS (
        SELECT
            cr.cr_returned_date_sk AS return_date_sk,
            cr.cr_item_sk AS item_sk,
            cr.cr_return_quantity AS return_qty,
            cr.cr_return_amount AS return_amt,
            cr.cr_return_tax AS return_tax,
            cr.cr_fee AS fee,
            cr.cr_refunded_cash AS refunded_cash,
            cr.cr_reversed_charge AS reversed_charge,
            cr.cr_store_credit AS store_credit,
            cr.cr_net_loss AS net_loss,
            d.d_year AS d_year,
            d.d_month_seq AS d_month_seq,
            i.i_category AS i_category,
            i.i_brand AS i_brand,
            CAST(NULL AS varchar) AS promo_id
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
    ),
    returns_store AS (
        SELECT
            sr.sr_returned_date_sk AS return_date_sk,
            sr.sr_item_sk AS item_sk,
            sr.sr_return_quantity AS return_qty,
            sr.sr_return_amt AS return_amt,
            sr.sr_return_tax AS return_tax,
            sr.sr_fee AS fee,
            sr.sr_refunded_cash AS refunded_cash,
            sr.sr_reversed_charge AS reversed_charge,
            sr.sr_store_credit AS store_credit,
            sr.sr_net_loss AS net_loss,
            d.d_year AS d_year,
            d.d_month_seq AS d_month_seq,
            i.i_category AS i_category,
            i.i_brand AS i_brand,
            CAST(NULL AS varchar) AS promo_id
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
    ),
    returns_web AS (
        SELECT
            wr.wr_returned_date_sk AS return_date_sk,
            wr.wr_item_sk AS item_sk,
            wr.wr_return_quantity AS return_qty,
            wr.wr_return_amt AS return_amt,
            wr.wr_return_tax AS return_tax,
            wr.wr_fee AS fee,
            wr.wr_refunded_cash AS refunded_cash,
            wr.wr_reversed_charge AS reversed_charge,
            wr.wr_account_credit AS store_credit,
            wr.wr_net_loss AS net_loss,
            d.d_year AS d_year,
            d.d_month_seq AS d_month_seq,
            i.i_category AS i_category,
            i.i_brand AS i_brand,
            CAST(NULL AS varchar) AS promo_id
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
    ),
    all_returns AS (
        SELECT * FROM returns_catalog
        UNION ALL
        SELECT * FROM returns_store
        UNION ALL
        SELECT * FROM returns_web
    ),
    return_summary AS (
        SELECT
            return_date_sk,
            SUM(return_qty) AS total_return_qty,
            SUM(return_amt) AS total_return_amt,
            SUM(net_loss) AS total_net_loss,
            d_year,
            d_month_seq,
            i_category,
            i_brand
        FROM all_returns
        GROUP BY return_date_sk, d_year, d_month_seq, i_category, i_brand
    ),
    quarter_profit AS (
        SELECT
            cs.cust_sk,
            cs.i_category,
            cs.i_brand,
            d.d_quarter_seq AS quarter_seq,
            SUM(cs.net_profit) AS quarter_profit,
            COUNT(*) AS quarter_cnt
        FROM combined_sales cs
        JOIN date_dim d ON cs.date_sk = d.d_date_sk
        GROUP BY cs.cust_sk, cs.i_category, cs.i_brand, d.d_quarter_seq
    ),
    avg_profit_prev_quarter AS (
        SELECT
            qp.cust_sk,
            qp.i_category,
            qp.i_brand,
            qp.quarter_seq,
            qp.quarter_profit / NULLIF(qp.quarter_cnt, 0) AS avg_profit_current_qtr,
            prev.quarter_profit / NULLIF(prev.quarter_cnt, 0) AS avg_profit_prior_qtr
        FROM quarter_profit qp
        LEFT JOIN quarter_profit prev
            ON qp.cust_sk = prev.cust_sk
            AND qp.i_category = prev.i_category
            AND qp.i_brand = prev.i_brand
            AND qp.quarter_seq = prev.quarter_seq + 1
    ),
    ranked_sales AS (
        SELECT
            cs.cust_sk,
            cs.date_sk,
            cs.store_name,
            cs.web_url,
            cs.i_category,
            cs.i_brand,
            cs.net_profit,
            cs.ext_sales_price,
            cs.ext_discount_amt,
            cs.quantity,
            d.d_year,
            d.d_month_seq,
            d.d_quarter_seq,
            CASE
                WHEN cs.ext_discount_amt > 1000 THEN 'HIGH'
                WHEN cs.ext_discount_amt BETWEEN 0 AND 1000 THEN 'MEDIUM'
                ELSE 'LOW'
            END AS discount_tier,
            ROW_NUMBER() OVER (PARTITION BY d.d_year, d.d_month_seq, cs.i_category ORDER BY cs.net_profit DESC) AS profit_rank,
            COALESCE(cs.promo_id, 'NO_PROMO') AS promo_id,
            CONCAT(COALESCE(cs.first_name, 'UNKNOWN'), ' ', COALESCE(cs.last_name, '')) AS customer_full_name,
            CASE
                WHEN cs.first_name IS NULL OR cs.last_name IS NULL THEN NULL
                ELSE reverse(cs.first_name) || '_' || reverse(cs.last_name)
            END AS rev_name_concat,
            nullif(cs.quantity, 0) AS quantity_nonzero,
            (cs.net_profit / nullif(cs.quantity, 0)) AS profit_per_qty,
            cs.net_profit + (
                SELECT COALESCE(SUM(r.total_net_loss), 0)
                FROM return_summary r
                WHERE r.d_year = d.d_year
                  AND r.d_month_seq = d.d_month_seq
                  AND r.i_category = cs.i_category
                  AND r.i_brand = cs.i_brand
            ) AS net_profit_adj,
            apq.avg_profit_prior_qtr
        FROM combined_sales cs
        JOIN date_dim d ON cs.date_sk = d.d_date_sk
        LEFT JOIN avg_profit_prev_quarter apq
            ON cs.cust_sk = apq.cust_sk
            AND cs.i_category = apq.i_category
            AND cs.i_brand = apq.i_brand
            AND d.d_quarter_seq = apq.quarter_seq
        WHERE cs.net_profit > 0
    )
SELECT
    rs.cust_sk,
    rs.cust_sk % 10 AS cust_bucket,
    rs.date_sk,
    d.d_date,
    rs.i_category,
    rs.i_brand,
    SUM(rs.net_profit) AS total_net_profit,
    SUM(rs.ext_sales_price) AS total_sales,
    AVG(CASE WHEN rs.discount_tier = 'HIGH' THEN rs.ext_discount_amt END) AS avg_high_discount,
    MAX(rs.profit_rank) AS max_rank,
    COUNT(DISTINCT rs.promo_id) AS distinct_promos,
    SUM(CASE WHEN rs.rev_name_concat IS NOT NULL THEN 1 ELSE 0 END) AS rev_name_nonnull_count,
    MIN(rs.profit_per_qty) AS min_profit_per_qty,
    MAX(rs.profit_per_qty) AS max_profit_per_qty,
    GROUPING(rs.i_category) AS cat_grouping,
    CAST(ROUND(AVG(rs.net_profit_adj), 2) AS DOUBLE) AS avg_adj_profit,
    array_join(array_agg(DISTINCT rs.promo_id), ',') AS promo_list
FROM ranked_sales rs
JOIN date_dim d ON rs.date_sk = d.d_date_sk
WHERE rs.profit_rank <= 5
  AND (rs.cust_sk IS NOT NULL OR rs.cust_sk IS NULL)
  AND (rs.cust_sk % 2 = 0 OR rs.cust_sk % 2 = 1)
GROUP BY
    rs.cust_sk,
    rs.cust_sk % 10,
    rs.date_sk,
    d.d_date,
    rs.i_category,
    rs.i_brand
HAVING SUM(rs.net_profit) > 0
   OR COUNT(*) = 0
ORDER BY total_net_profit DESC
LIMIT 100
