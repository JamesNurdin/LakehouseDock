WITH unified_sales AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_call_center_sk AS location_sk,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_promo_sk,
        ss.ss_store_sk,
        'store'
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ws.ws_promo_sk,
        ws.ws_web_page_sk,
        'web'
    FROM web_sales ws
),
sales_enriched AS (
    SELECT
        us.sold_date_sk,
        d.d_year,
        d.d_month_seq,
        us.item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_class,
        i.i_brand,
        us.sales_channel,
        us.quantity,
        us.net_paid,
        us.net_profit,
        us.promo_sk,
        p.p_promo_name,
        us.location_sk,
        CASE
            WHEN us.sales_channel = 'catalog' THEN cc.cc_name
            WHEN us.sales_channel = 'store' THEN s.s_store_name
            WHEN us.sales_channel = 'web' THEN wp.wp_url
            ELSE NULL
        END AS location_name
    FROM unified_sales us
    LEFT JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON us.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
    LEFT JOIN call_center cc ON us.sales_channel = 'catalog' AND us.location_sk = cc.cc_call_center_sk
    LEFT JOIN store s ON us.sales_channel = 'store' AND us.location_sk = s.s_store_sk
    LEFT JOIN web_page wp ON us.sales_channel = 'web' AND us.location_sk = wp.wp_web_page_sk
),
monthly_item_profit AS (
    SELECT
        d_year,
        d_month_seq,
        item_sk,
        i_item_id,
        i_product_name,
        i_category,
        SUM(net_profit) AS total_profit,
        SUM(net_paid) AS total_paid,
        SUM(quantity) AS total_quantity,
        COUNT(*) AS sales_transactions
    FROM sales_enriched
    GROUP BY d_year, d_month_seq, item_sk, i_item_id, i_product_name, i_category
),
ranked_monthly_items AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_profit DESC) AS profit_rank
    FROM monthly_item_profit
),
returns_aggregated AS (
    SELECT
        cr.cr_returned_date_sk AS return_date_sk,
        SUM(cr.cr_return_amount) AS return_amount,
        SUM(cr.cr_net_loss) AS return_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk
    UNION ALL
    SELECT
        sr.sr_returned_date_sk,
        SUM(sr.sr_return_amt),
        SUM(sr.sr_net_loss),
        COUNT(*)
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk
    UNION ALL
    SELECT
        wr.wr_returned_date_sk,
        SUM(wr.wr_return_amt),
        SUM(wr.wr_net_loss),
        COUNT(*)
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk
),
monthly_returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(r.return_amount) AS total_return_amount,
        SUM(r.return_loss) AS total_return_loss,
        SUM(r.return_cnt) AS total_return_cnt
    FROM returns_aggregated r
    LEFT JOIN date_dim d ON r.return_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    rmi.d_year,
    rmi.d_month_seq,
    rmi.item_sk,
    rmi.i_item_id,
    rmi.i_product_name,
    rmi.i_category,
    rmi.total_profit,
    rmi.total_paid,
    rmi.total_quantity,
    rmi.sales_transactions,
    mr.total_return_amount,
    mr.total_return_loss,
    mr.total_return_cnt,
    CASE WHEN rmi.total_profit = 0 THEN NULL ELSE mr.total_return_amount / rmi.total_profit END AS return_to_profit_ratio,
    rmi.profit_rank
FROM ranked_monthly_items rmi
LEFT JOIN monthly_returns mr
    ON rmi.d_year = mr.d_year AND rmi.d_month_seq = mr.d_month_seq
WHERE rmi.profit_rank <= 10
ORDER BY rmi.d_year, rmi.d_month_seq, rmi.profit_rank
