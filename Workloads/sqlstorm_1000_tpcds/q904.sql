WITH
store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_name AS channel,
        i.i_category,
        i.i_item_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS num_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY d.d_year, d.d_month_seq, s.s_store_name, i.i_category, i.i_item_sk
),
catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_name AS channel,
        i.i_category,
        i.i_item_sk,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS num_transactions
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY d.d_year, d.d_month_seq, cc.cc_name, i.i_category, i.i_item_sk
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        wp.wp_type AS channel,
        i.i_category,
        i.i_item_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS num_transactions
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY d.d_year, d.d_month_seq, wp.wp_type, i.i_category, i.i_item_sk
),
sales_agg AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
store_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_name AS channel,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY d.d_year, d.d_month_seq, s.s_store_name
),
catalog_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_name AS channel,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    GROUP BY d.d_year, d.d_month_seq, cc.cc_name
),
web_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        wp.wp_type AS channel,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY d.d_year, d.d_month_seq, wp.wp_type
),
returns_sum AS (
    SELECT
        d_year,
        d_month_seq,
        channel,
        SUM(total_return_loss) AS total_return_loss
    FROM (
        SELECT * FROM store_returns_agg
        UNION ALL
        SELECT * FROM catalog_returns_agg
        UNION ALL
        SELECT * FROM web_returns_agg
    ) t
    GROUP BY d_year, d_month_seq, channel
)
SELECT
    channel,
    d_year,
    d_month_seq,
    i_category,
    total_profit,
    total_sales,
    total_discount,
    total_return_loss,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_profit DESC) AS profit_rank
FROM (
    SELECT
        s.channel,
        s.d_year,
        s.d_month_seq,
        s.i_category,
        SUM(s.total_profit) AS total_profit,
        SUM(s.total_sales) AS total_sales,
        SUM(s.total_discount) AS total_discount,
        COALESCE(r.total_return_loss, 0) AS total_return_loss
    FROM sales_agg s
    LEFT JOIN returns_sum r
        ON s.d_year = r.d_year
       AND s.d_month_seq = r.d_month_seq
       AND s.channel = r.channel
    GROUP BY s.channel, s.d_year, s.d_month_seq, s.i_category, r.total_return_loss
    HAVING SUM(s.total_profit) > 0
) agg
ORDER BY d_year, d_month_seq, total_profit DESC
LIMIT 200
