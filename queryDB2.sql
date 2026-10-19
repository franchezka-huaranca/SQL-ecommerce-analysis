/* This is Task 1
Name: Franchezka Paulita HUARANCA ESPINOZA */

USE task2;
select count(is_public)
from playlists
where is_public is not null;

/* Query 1:*/
/*Objective: Identify most used deviced*/
select device, sum(ms_played) as times_streamed
from streams
group by device
order by times_streamed DESC;
/*Business value of the query: With this query we can identify the device mostly used by the users for streaming. Therefore this tell us what
features can be implemented in the streaming platform/app, and how to adapt it to the streaming patterns of the users.*/

/* Query 2*/
/*Objective: To identify tracks with the total streamed time and the artist*/
select t.track_id, t.title, a.artist_id, sum(s.ms_played) as sum_streamed
from tracks t
join streams s on t.track_id = s.track_id
join albums a on a.album_id = t.album_id
group by t.track_id
order by sum_streamed DESC;

/*Business value of the query: In this query we can find the list of the tracks with the total streamed time and the artist which this track
belong to. This is important to the company to find the most popular songs and to which artist they belong, so the company could keep
investing in the records of these artists.*/

/* Query 3*/
/*Objective: Identify the countries with higher streams*/
select u.country, sum(s.ms_played) as total_ms_streamed
from users u
join streams s
group by u.country
order by total_ms_streamed DESC;
/*Business value of the query: This query is important for indicating the performance of each country based on the total streamed time.
Directors can take advantage on which countries are performing better and benchmark the strategies employed by these countries into the
low-performing ones.*/

/*Query 4*/
/*Objective: To analyze the Content Gap*/
select g.genre_id, g.name as genre_name, count(s.stream_id) as total_streams_country
from genres g
join artist_genres ag
on g.genre_id = ag.genre_id
join artists a
on ag.artist_id = a.artist_id
join albums al
on a.artist_id = al.artist_id
join tracks t
on al.album_id = t.album_id
join streams s
on t.track_id = s.track_id
join users u
on s.user_id = u.user_id
where
	u.country = "FR"
    and a.artist_id NOT IN (
		select artist_id
        from artists
        where country = "FR"
        )
group by g.genre_id, g.name
order by total_streams_country DESC;

/*Business value of the query: With this query we identify the most popular music genres among France (FR),
that are currently supplied by non-French artists, providing a clear content acquisition target
for French based talent. Therefore, the company can also look for local uprising stars with this genres based
in the home country.*/

/* Query 5*/
/*Objective: To identify users who follow artists and stream their followed artists*/
select f.user_id, count(distinct s.track_id) as tracks_streamed, count(f.artist_id) as followed_artists
from follows f
join artists a 
on f.artist_id = a.artist_id
join albums al
on a.artist_id = al.artist_id
join tracks t
on al.album_id = t.album_id
join streams s
on s.track_id = t.track_id
and s.user_id = f.user_id
group by f.user_id;

/*Business value of the query: The output of this query tells us that every one of these users has listened to only one track from 
the one artist they follow. This actually shows a low level of engagement with the artists, as users follow artist, but do not stream
many tracks from their followed artists. Therefore, the company can boost engagement in the users with their artists. */

/* Query 6*/
/*Objective: To identify which track had a listening time below the average play time*/
with global_avg as (
	select avg(ms_played) as avg_play
    from streams
    )
select t.title, count(case when s.ms_played <= g.avg_play then 1 end)/ count(*) as below_global_avg_rate
from streams s
join tracks t
on s.track_id = t.track_id
cross join global_avg g
group by t.track_id
order by below_global_avg_rate;

/* For interpreting this query, the closer the avg is to 1, means most users stop early and derives to low engagement.
On the other hand, when the number is closer to 0, means that people listen longer than the average.
As the tracks are streamed usually one or max. 2 times, then is logical to obtain 0.000 or 1.000 values.
/*Business value of the query: Having a list of tracks with the highest engagement lets the company focus marketing and promotion 
on the songs most likely to drive streams and revenue. 

/* Query 7*/
/*Objective: To calculate (Streams from Playlists / Total Streams) * 100' */
select cast(sum(case when pt.track_id IS NOT NULL then 1 else 0 end) as real) * 100
    / count(s.stream_id) AS percentage_of_streams_from_playlists
from streams s
left join playlist_tracks pt 
on s.track_id = pt.track_id;

/*Business value of the query: The goal of this query is to determine the percentage of total streams that originate from a user
playing a track that is inside a custom-created playlist. If the number is close to 100%, this means that users are invested in this feature
and that they would have high switching costs(playlist are already created) to switch to another competitor.*/

/* Query 8*/
/*Objective: To calculate the average stream duration per artist*/
select a.artist_id, a.name as artist_name, 
	sum(s.ms_played) as total_miliseconds_streamed,
	count(s.stream_id) as total_streams,
    (sum(s.ms_played) * 1.0) / count(s.stream_id) as average_ms_played_per_stream
from artists a
join albums al on a.artist_id = al.artist_id
join tracks t on al.album_id = t.album_id
join streams s on t.track_id = s.track_id
group by a.artist_id, a.name
order by average_ms_played_per_stream DESC;

/*Business value of the query:This metric is more valid to evaluate the performance of the artist overall, and no by each track.
This can show a level of consistency, rather than just on one hit song. For the streaming company, when more data could be located,
can show the real performance of the artist based on the total streams of all is records, and to identify where to continue allocating
the investment in the royalties for the high-performing artists. */

/* Query 9*/
/*Objective: To identify content with category "explicit"*/
select al.album_id, al.title as album_title, a.name as artist_name, count(s.stream_id) as explicit_stream_count
from albums al
join artists a on al.artist_id = a.artist_id
join tracks t on al.album_id = t.album_id
join streams s on t.track_id = s.track_id
join users u on s.user_id = u.user_id
where t.explicit = 1
group by al.album_id, al.title, a.name
order by explicit_stream_count DESC;

/*Business value of the query: This query helps the Sales and Advertising teams target specific ad campaigns based on content consumption patterns, and for this case: explicit content.

/* Query 10*/
/*Objective: To analyze content discovery velocity*/
select
    case
        when datediff(pt.added_at, al.release_date) <= 7 then "New Release (< 7 Days)"
        else "Old Discovery (> 7 Days)"
    end as discovery_category,
    count(s.stream_id) as total_streams_from_playlist,
    count(distinct t.track_id) as unique_tracks_in_category,
    (cast(count(s.stream_id) as real) / count(distinct t.track_id)) as avg_streams_per_track_in_playlist
from tracks t
join albums al on t.album_id = al.album_id
join playlist_tracks pt on t.track_id = pt.track_id
join streams s on t.track_id = s.track_id
	where al.release_date IS NOT NULL
	and datediff(pt.added_at, al.release_date) >= 0
group by discovery_category
order by avg_streams_per_track_in_playlist DESC;
/*Business value of the query: From this query we can conclude that no user has saved and streamed a track within 7 days of its album release.
Therefore, this is not an indicator that the users interact with these platforms when there are new releases from this album
For the company, this information is important as it can be an indicator that the users do not engage soon with the platform.
In this case, the product managers can work on creating an special feature that notifies the users when a new release is approaching, and 
to facilitate the efforts of the users to add the songs to the playlists.