WITH
    store_sales_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            s.s_store_sk AS store_sk,
            s.s_store_name AS location_name,
            'Store' AS channel,
            p.p_promo_sk AS promo_sk,
            p.p_promo_name AS promo_name,
            i.i_item_sk AS item_sk,
            i.i_category AS category,
            SUM(ss.ss_net_profit) AS total_net_profit,
            SUM(ss.ss_quantity) AS total_quantity,
            SUM(ss.ss_ext_sales_price) AS total_sales_amount
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY
            d.d_year,
            d.d_month_seq,
            s.s_store_sk,
            s.s_store_name,
            p.p_promo_sk,
            p.p_promo_name,
            i.i_item_sk,
            i.i_category
    ),
    store_returns_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            s.s_store_sk AS store_sk,
            s.s_store_name AS location_name,
            p.p_promo_sk AS promo_sk,
            p.p_promo_name AS promo_name,
            i.i_item_sk AS item_sk,
            i.i_category AS category,
            SUM(sr.sr_return_amt) AS total_return_amount,
            SUM(sr.sr_return_tax) AS total_return_tax,
            SUM(sr.sr_return_amt_inc_tax) AS total_return_amount_inc_tax
        FROM store_returns sr
        JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
                           AND sr.sr_item_sk = ss.ss_item_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY
            d.d_year,
            d.d_month_seq,
            s.s_store_sk,
            s.s_store_name,
            p.p_promo_sk,
            p.p_promo_name,
            i.i_item_sk,
            i.i_category
    ),
    web_sales_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            w.web_site_sk AS site_sk,
            w.web_name AS location_name,
            'Web' AS channel,
            p.p_promo_sk AS promo_sk,
            p.p_promo_name AS promo_name,
            i.i_item_sk AS item_sk,
            i.i_category AS category,
            SUM(ws.ws_net_profit) AS total_net_profit,
            SUM(ws.ws_quantity) AS total_quantity,
            SUM(ws.ws_ext_sales_price) AS total_sales_amount
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
        GROUP BY
            d.d_year,
            d.d_month_seq,
            w.web_site_sk,
            w.web_name,
            p.p_promo_sk,
            p.p_promo_name,
            i.i_item_sk,
            i.i_category
    ),
    web_returns_agg AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            w.web_site_sk AS site_sk,
            w.web_name AS location_name,
            p.p_promo_sk AS promo_sk,
            p.p_promo_name AS promo_name,
            i.i_item_sk AS item_sk,
            i.i_category AS category,
            SUM(wr.wr_return_amt) AS total_return_amount,
            SUM(wr.wr_return_tax) AS total_return_tax,
            SUM(wr.wr_return_amt_inc_tax) AS total_return_amount_inc_tax
        FROM web_returns wr
        JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_item_sk = ws.ws_item_sk
        JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY
            d.d_year,
            d.d_month_seq,
            w.web_site_sk,
            w.web_name,
            p.p_promo_sk,
            p.p_promo_name,
            i.i_item_sk,
            i.i_category
    ),
    combined AS (
        SELECT
            ss.d_year,
            ss.d_month_seq,
            ss.location_name,
            ss.channel,
            ss.promo_name,
            ss.category,
            ss.total_net_profit,
            ss.total_quantity,
            ss.total_sales_amount,
            COALESCE(sr.total_return_amount, 0) AS total_return_amount,
            COALESCE(sr.total_return_tax, 0) AS total_return_tax,
            COALESCE(sr.total_return_amount_inc_tax, 0) AS total_return_amount_inc_tax
        FROM store_sales_agg ss
        LEFT JOIN store_returns_agg sr
            ON ss.d_year = sr.d_year
           AND ss.d_month_seq = sr.d_month_seq
           AND ss.store_sk = sr.store_sk
           AND ss.promo_sk = sr.promo_sk
           AND ss.item_sk = sr.item_sk
        UNION ALL
        SELECT
            ws.d_year,
            ws.d_month_seq,
            ws.location_name,
            ws.channel,
            ws.promo_name,
            ws.category,
            ws.total_net_profit,
            ws.total_quantity,
            ws.total_sales_amount,
            COALESCE(wr.total_return_amount, 0) AS total_return_amount,
            COALESCE(wr.total_return_tax, 0) AS total_return_tax,
            COALESCE(wr.total_return_amount_inc_tax, 0) AS total_return_amount_inc_tax
        FROM web_sales_agg ws
        LEFT JOIN web_returns_agg wr
            ON ws.d_year = wr.d_year
           AND ws.d_month_seq = wr.d_month_seq
           AND ws.site_sk = wr.site_sk
           AND ws.promo_sk = wr.promo_sk
           AND ws.item_sk = wr.item_sk
    )
SELECT
    d_year,
    d_month_seq,
    channel,
    location_name,
    promo_name,
    category,
    total_net_profit,
    total_quantity,
    total_sales_amount,
    total_return_amount,
    total_return_tax,
    total_return_amount_inc_tax,
    total_net_profit - total_return_amount_inc_tax AS net_profit_after_returns
FROM combined
ORDER BY
    d_year,
    d_month_seq,
    channel,
    location_name,
    promo_name
